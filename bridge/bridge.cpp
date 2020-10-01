#include "rtl.h"
#include "bridge.h"

#include <concepts>

uint64_t clk;
double sc_time_stamp() {
  return clk;
}

namespace mill::bridge {
  const size_t ADDR_WIDTH = 32;
  const size_t DATA_WIDTH = 32;

  template<std::unsigned_integral T>
  void assign_data(T &data, const rust::Vec<uint64_t> &input) {
    data = input[0];
  }

  class CPUImpl : public CPU {
  public:
    CPUImpl() {
      backend.rst = 1; // Initialize with reset
      mem_req_impl = new MemReqImpl(this);
      mem_resp_impl = new MemRespImpl(this);
    }

    ~CPUImpl() {
      delete this->mem_req_impl;
      delete this->mem_resp_impl;

      backend.final();
    }

    MemReq* mem_req() override {
      return this->mem_req_impl;
    }

    MemResp* mem_resp() override {
      return this->mem_resp_impl;
    }

    void set_int(size_t n) override {
      this->backend.ints |= 1 << n;
    }

    void clear_int(size_t n) override {
      this->backend.ints &= ~(1 << n);
    }

    void set_rst(bool rst) override {
      this->backend.rst = rst;
    }

    bool tick() override {
      // clk % 2 == 0, first half cycle
      backend.clk = 1;
      backend.eval();
      ++clk;

      // TODO: flush write

      // clk % 2 == 1, second half cycle
      backend.clk = 0;
      backend.eval();
      ++clk;

      return Verilated::gotFinish();
    }

  private:
    class MemReqImpl : public MemReq {
      private:
        CPUImpl *parent;

      public:
        MemReqImpl(CPUImpl *_parent) : parent(_parent) {}

        virtual bool read(uint64_t &result) override {
          parent->backend.mem_req_ready = true;
          result = parent->backend.mem_req_addr;
          return parent->backend.mem_req_valid != 0;
        }

        virtual void no_read() override {
          parent->backend.mem_req_ready = false;
        }
    };

    class MemRespImpl : public MemResp {
      private:
        CPUImpl *parent;

      public:
        MemRespImpl(CPUImpl *_parent) : parent(_parent) {}

        virtual bool write(const rust::Vec<uint64_t> &packed_data) override {
          parent->backend.mem_resp_valid = true;
          assign_data(parent->backend.mem_resp_data, packed_data);

          return parent->backend.mem_resp_ready;
        }

        virtual void no_write() override {
          parent->backend.mem_resp_valid = false;
          // TODO: write X
        }
    };

    rtl backend;
    MemReqImpl *mem_req_impl;
    MemRespImpl *mem_resp_impl;
  };

  std::unique_ptr<CPU> init() {
    // TODO: parse arguments
    // TODO: configurable clock rate
    const char** argv = nullptr;
    Verilated::commandArgs(0, argv);
    clk = 0;

    return std::make_unique<CPUImpl>();
  }

  void set_int(std::unique_ptr<CPU> &cpu, size_t n) {
    cpu->set_int(n);
  }
  void clear_int(std::unique_ptr<CPU> &cpu, size_t n) {
    cpu->clear_int(n);
  }
  void set_rst(std::unique_ptr<CPU> &cpu, bool rst) {
    cpu->set_rst(rst);
  }
  bool tick(std::unique_ptr<CPU> &cpu) {
    return cpu->tick();
  }

  std::unique_ptr<MemReq> mem_req(std::unique_ptr<CPU> &cpu) {
    return std::unique_ptr<MemReq>(cpu->mem_req());
  }
  std::unique_ptr<MemResp> mem_resp(std::unique_ptr<CPU> &cpu) {
    return std::unique_ptr<MemResp>(cpu->mem_resp());
  }

  bool read(std::unique_ptr<MemReq> &req, uint64_t &addr) {
    return req->read(addr);
  }
  void no_read(std::unique_ptr<MemReq> &req) {
    req->no_read();
  }

  bool write(std::unique_ptr<MemResp> &resp, const rust::Vec<uint64_t> &packed_data) {
    return resp->write(packed_data);
  }
  void no_write(std::unique_ptr<MemResp> &resp) {
    resp->no_write();
  }
}
