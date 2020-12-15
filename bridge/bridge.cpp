#include "rtl.h"
#include "bridge.h"

#include <verilated_fst_c.h>

#include <vector>
#include <string>
#include <optional>

uint64_t clk;
double sc_time_stamp() {
  return clk;
}

namespace mill::bridge {
  const size_t ADDR_WIDTH = 32;
  const size_t DATA_WIDTH = 32;

  template<typename T>
  void assign_data(T &data, const rust::Vec<uint64_t> &input) {
    data = input[0];
  }

  class CPUImpl : public CPU {
  public:
    CPUImpl(const rust::Str trace) {
      backend.rst = 1; // Initialize with reset
      backend.clk = 1; // Initialize to inactive clock edge

      if(trace.size() != 0) {
        Verilated::traceEverOn(true);
        tracer.emplace();
        backend.trace(&tracer.value(), 128);
        std::string std_trace = std::string(trace);
        tracer->open(std_trace.c_str());
      }

      this->backend.eval();
    }

    ~CPUImpl() {
      backend.final();
      if(tracer)
        tracer->close();
    }

    MemReq* mem_req() override {
      return new MemReqImpl(this);
    }

    MemResp* mem_resp() override {
      return new MemRespImpl(this);
    }

    void set_int(size_t n) override {
      this->backend.ints |= 1 << n;
      this->backend.eval();
    }

    void clear_int(size_t n) override {
      this->backend.ints &= ~(1 << n);
      this->backend.eval();
    }

    void set_rst(bool rst) override {
      this->backend.rst = rst;
      this->backend.eval();
    }

    bool tick() override {
      // clk % 2 == 0, we are on the inactive clock edge
      backend.clk = 0; // Negedge clk
      backend.eval();
      ++clk;

      // clk % 2 == 1, we are on the active clock edge
      if(tracer)
        tracer->dump(clk);
      backend.clk = 1; // Posedge clk
      backend.eval();
      ++clk;

      if(tracer)
        tracer->dump(clk);

      return Verilated::gotFinish();
    }

  private:
    class MemReqImpl : public MemReq {
      private:
        CPUImpl *parent;

      public:
        MemReqImpl(CPUImpl *_parent) : parent(_parent) {}

        virtual bool read(MemReqPacket &result) override {
          parent->backend.mem_req_ready = true;
          parent->backend.eval();

          result.addr = parent->backend.mem_req_addr;
          result.we = parent->backend.mem_req_we;
          result.be = parent->backend.mem_req_be;
          result.data = parent->backend.mem_req_data;

          return parent->backend.mem_req_valid != 0;
        }

        virtual void no_read() override {
          parent->backend.mem_req_ready = false;
          parent->backend.eval();
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
          parent->backend.eval();

          return parent->backend.mem_resp_ready;
        }

        virtual void no_write() override {
          parent->backend.mem_resp_valid = false;
          parent->backend.eval();
        }
    };

    rtl backend;
    std::optional<VerilatedFstC> tracer = std::nullopt;
  };

  std::unique_ptr<CPU> init(const rust::Vec<rust::String> &args, const rust::Str trace) {
    // TODO: configurable clock rate

    std::vector<std::string> std_args(args.size());
    std::vector<const char *> argv(args.size());
    for(size_t i = 0; i < args.size(); ++i) {
      std_args[i] = std::string(args[i]);
      argv[i] = std_args[i].c_str();
    }

    // Initialize verilator
    Verilated::commandArgs(args.size(), argv.data());

    // Initialize clk
    clk = 0;

    return std::make_unique<CPUImpl>(trace);
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

  bool read(std::unique_ptr<MemReq> &req, MemReqPacket &pack) {
    return req->read(pack);
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
