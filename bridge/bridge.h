#include <cstdint>
#include <memory>

#include "cxx.h"
#include "generated.h"

#ifndef __BRIDGE_H__
#define __BRIDGE_H__

namespace mill::bridge {
  struct MemReqPacket;

  class MemReq {
  public:
    virtual ~MemReq() {};
    virtual bool read(MemReqPacket &pack) = 0;
    virtual void no_read() = 0;
  };

  class MemResp {
  public:
    virtual ~MemResp() {};
    virtual bool write(const rust::Vec<uint64_t> &packed_data) = 0;
    virtual void no_write() = 0;
  };

  class CPU {
  public:
    virtual ~CPU() {};

    virtual MemReq* mem_req() = 0;
    virtual MemResp* mem_resp() = 0;
    virtual void set_int(size_t n) = 0;
    virtual void clear_int(size_t n) = 0;

    virtual void set_rst(bool rst) = 0;
    virtual bool tick() = 0;
  };

  std::unique_ptr<CPU> init(const rust::Vec<rust::String> &args, const rust::Str trace);
  void set_int(std::unique_ptr<CPU> &cpu, size_t n);
  void clear_int(std::unique_ptr<CPU> &cpu, size_t n);
  void set_rst(std::unique_ptr<CPU> &cpu, bool rst);
  bool tick(std::unique_ptr<CPU> &cpu);
  std::unique_ptr<MemReq> mem_req(std::unique_ptr<CPU> &cpu);
  std::unique_ptr<MemResp> mem_resp(std::unique_ptr<CPU> &cpu);

  bool read(std::unique_ptr<MemReq> &req, MemReqPacket &pack);
  void no_read(std::unique_ptr<MemReq> &req);

  bool write(std::unique_ptr<MemResp> &resp, const rust::Vec<uint64_t> &packed_data);
  void no_write(std::unique_ptr<MemResp> &resp);
}

#endif // __BRIDGE_H__
