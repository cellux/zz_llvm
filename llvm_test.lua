local testing = require('testing')
local llvm = require('llvm')
local assert = require('assert')
local ffi = require('ffi')

testing("MemoryBuffer", function()
   local s = "Hello, world!"
   local buf = llvm.MemoryBuffer(s)
   assert.equals(buf:GetBufferSize(), #s)
   assert.equals(ffi.string(buf:GetBufferStart(), #s), s)
   buf:delete()
end)

testing("Context", function()
   local ctx = llvm.Context()
   ctx:delete()
end)

testing("GetDefaultTargetTriple", function()
   local triple = llvm.GetDefaultTargetTriple()
   assert.type(triple, 'string')
   --[[
   pf("default target triple: %s", triple)
   local target = llvm.GetTargetFromTriple(triple)
   pf("target name: %s", target:GetTargetName())
   pf("target description: %s", target:GetTargetDescription())
   pf("target has jit: %s", target:TargetHasJIT())
   pf("target has target machine: %s", target:TargetHasTargetMachine())
   pf("target has asm backend: %s", target:TargetHasAsmBackend())
   --]]
end)

testing("GetFunctionAddress", function()
   local ctx = llvm.Context()
   local m = ctx:ParseIR [[
     define i32 @main() {
       ret i32 13
     }
   ]]
   local options = llvm.MCJITCompilerOptions {
      OptLevel = llvm.LLVMCodeGenLevelDefault
   }
   local ee = llvm.CreateMCJITCompilerForModule(m, options)
   local f = ffi.cast("int32_t (*)()", ee:GetFunctionAddress("main"))
   assert.not_nil(f)
   assert.equals(f(), 13)
   ee:delete()
   ctx:delete()
end)
