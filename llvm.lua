local ffi = require('ffi')

-- This module decidedly does NOT expose details of the instruction
-- builder, basic block management and similar interfaces. I hold the
-- opinion that the LLVM C API will always lag behind the C++ one and
-- thus the best possible option for consumers of the C API is to
-- generate the LLVM IR in textual form and then feed it to the LLVM
-- parse/compile/link stages whose C API is relatively stable.

ffi.cdef [[

/*** Types.h ***/

typedef int LLVMBool;

typedef struct LLVMOpaqueMemoryBuffer *LLVMMemoryBufferRef;
typedef struct LLVMOpaqueContext *LLVMContextRef;
typedef struct LLVMOpaqueModule *LLVMModuleRef;
typedef struct LLVMOpaqueType *LLVMTypeRef;
typedef struct LLVMOpaqueValue *LLVMValueRef;
typedef struct LLVMOpaqueBasicBlock *LLVMBasicBlockRef;
typedef struct LLVMOpaqueMetadata *LLVMMetadataRef;
typedef struct LLVMOpaqueBuilder *LLVMBuilderRef;
typedef struct LLVMOpaqueDIBuilder *LLVMDIBuilderRef;
typedef struct LLVMOpaqueModuleProvider *LLVMModuleProviderRef;
typedef struct LLVMOpaquePassManager *LLVMPassManagerRef;
typedef struct LLVMOpaquePassRegistry *LLVMPassRegistryRef;
typedef struct LLVMOpaqueUse *LLVMUseRef;
typedef struct LLVMOpaqueAttributeRef *LLVMAttributeRef;
typedef struct LLVMOpaqueDiagnosticInfo *LLVMDiagnosticInfoRef;

/*** Core.h ***/

/* error handling */

char *LLVMCreateMessage(const char *Message);
void LLVMDisposeMessage(char *Message);

/* context */

LLVMContextRef LLVMContextCreate(void);
void LLVMContextDispose(LLVMContextRef C);

/* modules */

LLVMModuleRef LLVMModuleCreateWithNameInContext(const char *ModuleID, LLVMContextRef C);
LLVMModuleRef LLVMCloneModule(LLVMModuleRef M);
const char *LLVMGetModuleIdentifier(LLVMModuleRef M, size_t *Len);
void LLVMSetModuleIdentifier(LLVMModuleRef M, const char *Ident, size_t Len);
const char *LLVMGetDataLayoutStr(LLVMModuleRef M);
void LLVMSetDataLayout(LLVMModuleRef M, const char *DataLayoutStr);
const char *LLVMGetTarget(LLVMModuleRef M);
void LLVMSetTarget(LLVMModuleRef M, const char *Triple);
void LLVMDumpModule(LLVMModuleRef M);
LLVMBool LLVMPrintModuleToFile(LLVMModuleRef M, const char *Filename, char **ErrorMessage);
char *LLVMPrintModuleToString(LLVMModuleRef M);
void LLVMDisposeModule(LLVMModuleRef M);

/* types */

typedef enum {
  LLVMVoidTypeKind,        /**< type with no size */
  LLVMHalfTypeKind,        /**< 16 bit floating point type */
  LLVMFloatTypeKind,       /**< 32 bit floating point type */
  LLVMDoubleTypeKind,      /**< 64 bit floating point type */
  LLVMX86_FP80TypeKind,    /**< 80 bit floating point type (X87) */
  LLVMFP128TypeKind,       /**< 128 bit floating point type (112-bit mantissa)*/
  LLVMPPC_FP128TypeKind,   /**< 128 bit floating point type (two 64-bits) */
  LLVMLabelTypeKind,       /**< Labels */
  LLVMIntegerTypeKind,     /**< Arbitrary bit width integers */
  LLVMFunctionTypeKind,    /**< Functions */
  LLVMStructTypeKind,      /**< Structures */
  LLVMArrayTypeKind,       /**< Arrays */
  LLVMPointerTypeKind,     /**< Pointers */
  LLVMVectorTypeKind,      /**< SIMD 'packed' format, or other vector type */
  LLVMMetadataTypeKind,    /**< Metadata */
  LLVMX86_MMXTypeKind,     /**< X86 MMX */
  LLVMTokenTypeKind        /**< Tokens */
} LLVMTypeKind;

LLVMTypeKind LLVMGetTypeKind(LLVMTypeRef Ty);
LLVMBool LLVMTypeIsSized(LLVMTypeRef Ty);
void LLVMDumpType(LLVMTypeRef Val);
char *LLVMPrintTypeToString(LLVMTypeRef Val);

LLVMValueRef LLVMAlignOf(LLVMTypeRef Ty);
LLVMValueRef LLVMSizeOf(LLVMTypeRef Ty);

/* integer types */

LLVMTypeRef LLVMInt1TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt8TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt16TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt32TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt64TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMIntTypeInContext(LLVMContextRef C, unsigned NumBits);

unsigned LLVMGetIntTypeWidth(LLVMTypeRef IntegerTy);

/* floating point types */

LLVMTypeRef LLVMHalfTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMFloatTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMDoubleTypeInContext(LLVMContextRef C);

/* structure types */

LLVMTypeRef LLVMStructTypeInContext(
  LLVMContextRef C,
  LLVMTypeRef *ElementTypes,
  unsigned ElementCount,
  LLVMBool Packed);

/* sequential types */

LLVMTypeRef LLVMArrayType(
  LLVMTypeRef ElementType,
  unsigned ElementCount);

LLVMTypeRef LLVMPointerType(
  LLVMTypeRef ElementType,
  unsigned AddressSpace);

LLVMTypeRef LLVMVectorType(
  LLVMTypeRef ElementType,
  unsigned ElementCount);

/* other types */

LLVMTypeRef LLVMVoidTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMLabelTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMX86MMXTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMTokenTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMMetadataTypeInContext(LLVMContextRef C);

/* values */

LLVMTypeRef LLVMTypeOf(LLVMValueRef Val);

typedef enum {
  LLVMArgumentValueKind,
  LLVMBasicBlockValueKind,
  LLVMMemoryUseValueKind,
  LLVMMemoryDefValueKind,
  LLVMMemoryPhiValueKind,

  LLVMFunctionValueKind,
  LLVMGlobalAliasValueKind,
  LLVMGlobalIFuncValueKind,
  LLVMGlobalVariableValueKind,
  LLVMBlockAddressValueKind,
  LLVMConstantExprValueKind,
  LLVMConstantArrayValueKind,
  LLVMConstantStructValueKind,
  LLVMConstantVectorValueKind,

  LLVMUndefValueValueKind,
  LLVMConstantAggregateZeroValueKind,
  LLVMConstantDataArrayValueKind,
  LLVMConstantDataVectorValueKind,
  LLVMConstantIntValueKind,
  LLVMConstantFPValueKind,
  LLVMConstantPointerNullValueKind,
  LLVMConstantTokenNoneValueKind,

  LLVMMetadataAsValueValueKind,
  LLVMInlineAsmValueKind,

  LLVMInstructionValueKind,
} LLVMValueKind;

LLVMValueKind LLVMGetValueKind(LLVMValueRef Val);

const char *LLVMGetValueName(LLVMValueRef Val);
void LLVMSetValueName(LLVMValueRef Val, const char *Name);

void LLVMDumpValue(LLVMValueRef Val);
char *LLVMPrintValueToString(LLVMValueRef Val);

void LLVMReplaceAllUsesWith(LLVMValueRef OldVal, LLVMValueRef NewVal);

LLVMBool LLVMIsConstant(LLVMValueRef Val);
LLVMBool LLVMIsUndef(LLVMValueRef Val);
LLVMBool LLVMIsNull(LLVMValueRef Val);

unsigned LLVMGetAlignment(LLVMValueRef V);
void LLVMSetAlignment(LLVMValueRef V, unsigned Bytes);

/* constants */

LLVMValueRef LLVMConstNull(LLVMTypeRef Ty); /* all zeroes */
LLVMValueRef LLVMConstAllOnes(LLVMTypeRef Ty);
LLVMValueRef LLVMConstPointerNull(LLVMTypeRef Ty);

LLVMValueRef LLVMGetUndef(LLVMTypeRef Ty);

LLVMValueRef LLVMConstInt(
  LLVMTypeRef IntTy,
  unsigned long long N,
  LLVMBool SignExtend);

LLVMValueRef LLVMConstIntOfString(
  LLVMTypeRef IntTy,
  const char *Text,
  uint8_t Radix);

LLVMValueRef LLVMConstReal(
  LLVMTypeRef RealTy,
  double N);

LLVMValueRef LLVMConstRealOfString(
  LLVMTypeRef RealTy,
  const char *Text);

LLVMValueRef LLVMConstStringInContext(
  LLVMContextRef C,
  const char *Str, 
  unsigned Length,
  LLVMBool DontNullTerminate);

LLVMValueRef LLVMConstStructInContext(
  LLVMContextRef C,
  LLVMValueRef *ConstantVals,
  unsigned Count,
  LLVMBool Packed);

LLVMValueRef LLVMConstNamedStruct(
  LLVMTypeRef StructTy,
  LLVMValueRef *ConstantVals,
  unsigned Count);

LLVMValueRef LLVMConstArray(
  LLVMTypeRef ElementTy,
  LLVMValueRef *ConstantVals,
  unsigned Length);

LLVMValueRef LLVMConstVector(
  LLVMValueRef *ScalarConstantVals,
  unsigned Size);

LLVMValueRef LLVMConstGEP(
  LLVMValueRef ConstantVal,
  LLVMValueRef *ConstantIndices,
  unsigned NumIndices);

/* global variables */

LLVMValueRef LLVMAddGlobal(
  LLVMModuleRef M,
  LLVMTypeRef Ty,
  const char *Name);

LLVMValueRef LLVMGetNamedGlobal(
  LLVMModuleRef M,
  const char *Name);

LLVMValueRef LLVMGetInitializer(
  LLVMValueRef GlobalVar);

void LLVMSetInitializer(
  LLVMValueRef GlobalVar,
  LLVMValueRef ConstantVal);

LLVMBool LLVMIsGlobalConstant(
  LLVMValueRef GlobalVar);

void LLVMSetGlobalConstant(
  LLVMValueRef GlobalVar,
  LLVMBool IsConstant);

LLVMBool LLVMIsExternallyInitialized(
  LLVMValueRef GlobalVar);

void LLVMSetExternallyInitialized(
  LLVMValueRef GlobalVar,
  LLVMBool IsExtInit);

/* linkage */

typedef enum {
  LLVMExternalLinkage,    /**< Externally visible function */
  LLVMAvailableExternallyLinkage,
  LLVMLinkOnceAnyLinkage, /**< Keep one copy of function when linking (inline)*/
  LLVMLinkOnceODRLinkage, /**< Same, but only replaced by something
                            equivalent. */
  LLVMLinkOnceODRAutoHideLinkage, /**< Obsolete */
  LLVMWeakAnyLinkage,     /**< Keep one copy of function when linking (weak) */
  LLVMWeakODRLinkage,     /**< Same, but only replaced by something
                            equivalent. */
  LLVMAppendingLinkage,   /**< Special purpose, only applies to global arrays */
  LLVMInternalLinkage,    /**< Rename collisions when linking (static
                               functions) */
  LLVMPrivateLinkage,     /**< Like Internal, but omit from symbol table */
  LLVMDLLImportLinkage,   /**< Obsolete */
  LLVMDLLExportLinkage,   /**< Obsolete */
  LLVMExternalWeakLinkage,/**< ExternalWeak linkage description */
  LLVMGhostLinkage,       /**< Obsolete */
  LLVMCommonLinkage,      /**< Tentative definitions */
  LLVMLinkerPrivateLinkage, /**< Like Private, but linker removes. */
  LLVMLinkerPrivateWeakLinkage /**< Like LinkerPrivate, but is weak. */
} LLVMLinkage;

LLVMLinkage LLVMGetLinkage(LLVMValueRef Global);
void LLVMSetLinkage(LLVMValueRef Global, LLVMLinkage Linkage);

/* functions */

LLVMTypeRef LLVMFunctionType(
  LLVMTypeRef ReturnType,
  LLVMTypeRef *ParamTypes,
  unsigned ParamCount,
  LLVMBool IsVarArg);

LLVMValueRef LLVMAddFunction(
  LLVMModuleRef M,
  const char *Name,
  LLVMTypeRef FunctionTy);

LLVMValueRef LLVMGetNamedFunction(
  LLVMModuleRef M,
  const char *Name);

typedef enum {
  LLVMCCallConv           = 0,
  LLVMFastCallConv        = 8,
  LLVMColdCallConv        = 9,
  LLVMWebKitJSCallConv    = 12,
  LLVMAnyRegCallConv      = 13,
  LLVMX86StdcallCallConv  = 64,
  LLVMX86FastcallCallConv = 65
} LLVMCallConv;

unsigned LLVMGetFunctionCallConv(LLVMValueRef Fn);
void LLVMSetFunctionCallConv(LLVMValueRef Fn, unsigned CC);

/* module providers */

LLVMModuleProviderRef LLVMCreateModuleProviderForExistingModule(LLVMModuleRef M);
void LLVMDisposeModuleProvider(LLVMModuleProviderRef M);

/* memory buffers */

LLVMBool LLVMCreateMemoryBufferWithContentsOfFile(
  const char *Path,
  LLVMMemoryBufferRef *OutMemBuf,
  char **OutMessage);

LLVMMemoryBufferRef LLVMCreateMemoryBufferWithMemoryRange(
  const char *InputData,
  size_t InputDataLength,
  const char *BufferName,
  LLVMBool RequiresNullTerminator);

LLVMMemoryBufferRef LLVMCreateMemoryBufferWithMemoryRangeCopy(
  const char *InputData,
  size_t InputDataLength,
  const char *BufferName);

const char *LLVMGetBufferStart(LLVMMemoryBufferRef MemBuf);

size_t LLVMGetBufferSize(LLVMMemoryBufferRef MemBuf);

void LLVMDisposeMemoryBuffer(LLVMMemoryBufferRef MemBuf);

/* pass registry */

LLVMPassRegistryRef LLVMGetGlobalPassRegistry(void);

/* pass manager */

LLVMPassManagerRef LLVMCreatePassManager(void);
LLVMPassManagerRef LLVMCreateFunctionPassManagerForModule(LLVMModuleRef M);
LLVMBool LLVMRunPassManager(LLVMPassManagerRef PM, LLVMModuleRef M);
void LLVMDisposePassManager(LLVMPassManagerRef PM);

/*** Analysis.h ***/

typedef enum {
  LLVMAbortProcessAction, /* verifier will print to stderr and abort() */
  LLVMPrintMessageAction, /* verifier will print to stderr and return 1 */
  LLVMReturnStatusAction  /* verifier will just return 1 */
} LLVMVerifierFailureAction;

LLVMBool LLVMVerifyModule(
  LLVMModuleRef M,
  LLVMVerifierFailureAction Action,
  char **OutMessage);

LLVMBool LLVMVerifyFunction(
  LLVMValueRef Fn,
  LLVMVerifierFailureAction Action);

/*** Bitreader.h ***/

LLVMBool LLVMParseBitcodeInContext2(
  LLVMContextRef ContextRef,
  LLVMMemoryBufferRef MemBuf,
  LLVMModuleRef *OutModule);

LLVMBool LLVMGetBitcodeModuleInContext2(
  LLVMContextRef ContextRef,
  LLVMMemoryBufferRef MemBuf,
  LLVMModuleRef *OutM);

/*** Bitwriter.h */

int LLVMWriteBitcodeToFile(
  LLVMModuleRef M,
  const char *Path);

int LLVMWriteBitcodeToFD(
  LLVMModuleRef M,
  int FD,
  int ShouldClose,
  int Unbuffered);

LLVMMemoryBufferRef LLVMWriteBitcodeToMemoryBuffer(
  LLVMModuleRef M);

/*** IRReader.h ***/

LLVMBool LLVMParseIRInContext(
  LLVMContextRef ContextRef,
  LLVMMemoryBufferRef MemBuf,
  LLVMModuleRef *OutM,
  char **OutMessage);

/*** Linker.h ***/

LLVMBool LLVMLinkModules2(
  LLVMModuleRef Dest,
  LLVMModuleRef Src);

/*** Target.h ***/

enum LLVMByteOrdering { LLVMBigEndian, LLVMLittleEndian };

typedef struct LLVMOpaqueTargetData *LLVMTargetDataRef;
typedef struct LLVMOpaqueTargetLibraryInfotData *LLVMTargetLibraryInfoRef;

LLVMTargetDataRef LLVMGetModuleDataLayout(LLVMModuleRef M);
void LLVMSetModuleDataLayout(LLVMModuleRef M, LLVMTargetDataRef DL);

LLVMTargetDataRef LLVMCreateTargetData(const char *StringRep);
void LLVMDisposeTargetData(LLVMTargetDataRef TD);

char *LLVMCopyStringRepOfTargetData(LLVMTargetDataRef TD);

enum LLVMByteOrdering LLVMByteOrder(LLVMTargetDataRef TD);
unsigned LLVMPointerSize(LLVMTargetDataRef TD);
LLVMTypeRef LLVMIntPtrTypeInContext(LLVMContextRef C, LLVMTargetDataRef TD);
unsigned long long LLVMSizeOfTypeInBits(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned long long LLVMStoreSizeOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned long long LLVMABISizeOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMABIAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMCallFrameAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMPreferredAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMPreferredAlignmentOfGlobal(LLVMTargetDataRef TD,
                                        LLVMValueRef GlobalVar);
unsigned LLVMElementAtOffset(LLVMTargetDataRef TD, LLVMTypeRef StructTy,
                             unsigned long long Offset);
unsigned long long LLVMOffsetOfElement(LLVMTargetDataRef TD,
                                       LLVMTypeRef StructTy, unsigned Element);

/*** TargetMachine.h ***/

typedef struct LLVMOpaqueTargetMachine *LLVMTargetMachineRef;
typedef struct LLVMTarget *LLVMTargetRef;

typedef enum {
    LLVMCodeGenLevelNone,
    LLVMCodeGenLevelLess,
    LLVMCodeGenLevelDefault,
    LLVMCodeGenLevelAggressive
} LLVMCodeGenOptLevel;

typedef enum {
    LLVMRelocDefault,
    LLVMRelocStatic,
    LLVMRelocPIC,
    LLVMRelocDynamicNoPic
} LLVMRelocMode;

typedef enum {
    LLVMCodeModelDefault,
    LLVMCodeModelJITDefault,
    LLVMCodeModelSmall,
    LLVMCodeModelKernel,
    LLVMCodeModelMedium,
    LLVMCodeModelLarge
} LLVMCodeModel;

typedef enum {
    LLVMAssemblyFile,
    LLVMObjectFile
} LLVMCodeGenFileType;

/* target */

LLVMTargetRef LLVMGetFirstTarget(void);
LLVMTargetRef LLVMGetNextTarget(LLVMTargetRef T);

LLVMTargetRef LLVMGetTargetFromName(const char *Name);

LLVMBool LLVMGetTargetFromTriple(
  const char* Triple,
  LLVMTargetRef *T,
  char **ErrorMessage);

const char *LLVMGetTargetName(LLVMTargetRef T);
const char *LLVMGetTargetDescription(LLVMTargetRef T);

LLVMBool LLVMTargetHasJIT(LLVMTargetRef T);
LLVMBool LLVMTargetHasTargetMachine(LLVMTargetRef T);
LLVMBool LLVMTargetHasAsmBackend(LLVMTargetRef T);

/* target machine */

LLVMTargetMachineRef LLVMCreateTargetMachine(
  LLVMTargetRef T,
  const char *Triple,
  const char *CPU,
  const char *Features,
  LLVMCodeGenOptLevel Level,
  LLVMRelocMode Reloc,
  LLVMCodeModel CodeModel);

LLVMTargetRef LLVMGetTargetMachineTarget(LLVMTargetMachineRef T);

char *LLVMGetTargetMachineTriple(LLVMTargetMachineRef T);
char *LLVMGetTargetMachineCPU(LLVMTargetMachineRef T);
char *LLVMGetTargetMachineFeatureString(LLVMTargetMachineRef T);

LLVMTargetDataRef LLVMCreateTargetDataLayout(LLVMTargetMachineRef T);

void LLVMSetTargetMachineAsmVerbosity(
  LLVMTargetMachineRef T,
  LLVMBool VerboseAsm);

LLVMBool LLVMTargetMachineEmitToFile(
  LLVMTargetMachineRef T,
  LLVMModuleRef M,
  char *Filename,
  LLVMCodeGenFileType codegen,
  char **ErrorMessage);

LLVMBool LLVMTargetMachineEmitToMemoryBuffer(
  LLVMTargetMachineRef T,
  LLVMModuleRef M,
  LLVMCodeGenFileType codegen,
  char** ErrorMessage,
  LLVMMemoryBufferRef *OutMemBuf);

void LLVMAddAnalysisPasses(
  LLVMTargetMachineRef T,
  LLVMPassManagerRef PM);

void LLVMDisposeTargetMachine(
  LLVMTargetMachineRef T);

/* triple */

char* LLVMGetDefaultTargetTriple(void);

/*** ExecutionEngine.h ***/

/* generic values */

typedef struct LLVMOpaqueGenericValue *LLVMGenericValueRef;

LLVMGenericValueRef LLVMCreateGenericValueOfInt(
  LLVMTypeRef Ty,
  unsigned long long N,
  LLVMBool IsSigned);

LLVMGenericValueRef LLVMCreateGenericValueOfPointer(
  void *P);

LLVMGenericValueRef LLVMCreateGenericValueOfFloat(
  LLVMTypeRef Ty,
  double N);

unsigned LLVMGenericValueIntWidth(
  LLVMGenericValueRef GenValRef);

unsigned long long LLVMGenericValueToInt(
  LLVMGenericValueRef GenVal,
  LLVMBool IsSigned);

void *LLVMGenericValueToPointer(
  LLVMGenericValueRef GenVal);

double LLVMGenericValueToFloat(
  LLVMTypeRef TyRef,
  LLVMGenericValueRef GenVal);

void LLVMDisposeGenericValue(
  LLVMGenericValueRef GenVal);

/* MCJIT */

typedef struct LLVMOpaqueMCJITMemoryManager *LLVMMCJITMemoryManagerRef;

struct LLVMMCJITCompilerOptions {
  unsigned OptLevel;
  LLVMCodeModel CodeModel;
  LLVMBool NoFramePointerElim;
  LLVMBool EnableFastISel;
  LLVMMCJITMemoryManagerRef MCJMM;
};

void LLVMInitializeMCJITCompilerOptions(
  struct LLVMMCJITCompilerOptions *Options,
  size_t SizeOfOptions);

/* execution engine */

typedef struct LLVMOpaqueExecutionEngine *LLVMExecutionEngineRef;

void LLVMLinkInMCJIT(void);
void LLVMLinkInInterpreter(void);

LLVMBool LLVMCreateExecutionEngineForModule(
  LLVMExecutionEngineRef *OutEE,
  LLVMModuleRef M,
  char **OutError);

LLVMBool LLVMCreateInterpreterForModule(
  LLVMExecutionEngineRef *OutInterp,
  LLVMModuleRef M,
  char **OutError);

LLVMBool LLVMCreateJITCompilerForModule(
  LLVMExecutionEngineRef *OutJIT,
  LLVMModuleRef M,
  unsigned OptLevel,
  char **OutError);

LLVMBool LLVMCreateMCJITCompilerForModule(
  LLVMExecutionEngineRef *OutJIT,
  LLVMModuleRef M,
  struct LLVMMCJITCompilerOptions *Options,
  size_t SizeOfOptions,
  char **OutError);

void LLVMRunStaticConstructors(
  LLVMExecutionEngineRef EE);

void LLVMRunStaticDestructors(
  LLVMExecutionEngineRef EE);

int LLVMRunFunctionAsMain(
  LLVMExecutionEngineRef EE,
  LLVMValueRef F,
  unsigned ArgC,
  const char * const *ArgV,
  const char * const *EnvP);

LLVMGenericValueRef LLVMRunFunction(
  LLVMExecutionEngineRef EE,
  LLVMValueRef F,
  unsigned NumArgs,
  LLVMGenericValueRef *Args);

void LLVMFreeMachineCodeForFunction(
  LLVMExecutionEngineRef EE,
  LLVMValueRef F);

void LLVMAddModule(
  LLVMExecutionEngineRef EE,
  LLVMModuleRef M);

LLVMBool LLVMFindFunction(
  LLVMExecutionEngineRef EE,
  const char *Name,
  LLVMValueRef *OutFn);

void *LLVMRecompileAndRelinkFunction(
  LLVMExecutionEngineRef EE,
  LLVMValueRef Fn);

LLVMTargetDataRef LLVMGetExecutionEngineTargetData(
  LLVMExecutionEngineRef EE);

LLVMTargetMachineRef LLVMGetExecutionEngineTargetMachine(
  LLVMExecutionEngineRef EE);

void LLVMAddGlobalMapping(
  LLVMExecutionEngineRef EE,
  LLVMValueRef Global,
  void* Addr);

void *LLVMGetPointerToGlobal(
  LLVMExecutionEngineRef EE,
  LLVMValueRef Global);

uint64_t LLVMGetGlobalValueAddress(
  LLVMExecutionEngineRef EE,
  const char *Name);

uint64_t LLVMGetFunctionAddress(
  LLVMExecutionEngineRef EE,
  const char *Name);

void LLVMDisposeExecutionEngine(LLVMExecutionEngineRef EE);

]]

local llvm = ffi.load('LLVM.so')

local luajit_arch_to_llvm_target = {
   x86 = "X86",
   arm = "ARM",
   ppc = "PowerPC",
   mips = "Mips",
}

local target_initializers = {
   "TargetInfo",
   "Target",
   "TargetMC",
   "AsmPrinter",
   "AsmParser",
   --"Disassember",
}

local function initialize_target(target)
   for _,initializer in ipairs(target_initializers) do
      ffi.cdef("void LLVMInitialize"..target..initializer.."(void);")
      llvm["LLVMInitialize"..target..initializer]()
   end
end

local llvm_target = luajit_arch_to_llvm_target[ffi.arch]
if not llvm_target then
   ef("LLVM is not supported on this architecture: %s", ffi.arch)
end

initialize_target(llvm_target)

local M = {}

local function LLVMBool(x)
   return x and 1 or 0
end

local function DisposeMessage(msg)
   local s = ffi.string(msg)
   llvm.LLVMDisposeMessage(msg)
   return s
end

local function TypeRefArray(types)
   local refs = ffi.new("LLVMTypeRef[?]", #types)
   for i=1,#types do
      refs[i-1] = types[i].ty
   end
   return refs
end

local function ValueRefArray(vals)
   local refs = ffi.new("LLVMValueRef[?]", #vals)
   for i=1,#vals do
      refs[i-1] = vals[i].val
   end
   return refs
end

local function GenericValueRefArray(vals)
   local refs = ffi.new("LLVMGenericValueRef[?]", #vals)
   for i=1,#vals do
      refs[i-1] = vals[i].genval
   end
   return refs
end

local Type, Value, Module, Context

-- MemoryBuffer

ffi.cdef [[ struct zz_llvm_MemoryBuffer { LLVMMemoryBufferRef buf; }; ]]

local MemoryBuffer_mt = {}

function MemoryBuffer_mt:GetBufferStart()
   return llvm.LLVMGetBufferStart(self.buf)
end

function MemoryBuffer_mt:GetBufferSize()
   return llvm.LLVMGetBufferSize(self.buf)
end

function MemoryBuffer_mt:DisposeMemoryBuffer()
   if self.buf ~= nil then
      llvm.LLVMDisposeMemoryBuffer(self.buf)
      self.buf = nil
   end
end
MemoryBuffer_mt.delete = MemoryBuffer_mt.DisposeMemoryBuffer

MemoryBuffer_mt.__index = MemoryBuffer_mt
MemoryBuffer_mt.__gc = MemoryBuffer_mt.delete

local MemoryBuffer = ffi.metatype("struct zz_llvm_MemoryBuffer", MemoryBuffer_mt)

function M.CreateMemoryBufferWithMemoryRange(InputData, InputDataLength, BufferName, RequiresNullTerminator)
   return MemoryBuffer(llvm.LLVMCreateMemoryBufferWithMemoryRange(
                          InputData,
                          InputDataLength,
                          BufferName,
                          LLVMBool(RequiresNullTerminator)))
end

function M.CreateMemoryBufferWithMemoryRangeCopy(InputData, InputDataLength, BufferName)
   return MemoryBuffer(llvm.LLVMCreateMemoryBufferWithMemoryRangeCopy(
                          InputData,
                          InputDataLength,
                          BufferName))
end

function M.MemoryBuffer(buf, name)
   return M.CreateMemoryBufferWithMemoryRangeCopy(buf, #buf, name)
end

-- TargetData

ffi.cdef [[ struct zz_llvm_TargetData { LLVMTargetDataRef td; }; ]]

local TargetData_mt = {}

function TargetData_mt:__tostring()
   return DisposeMessage(llvm.LLVMCopyStringRepOfTargetData(self.td))
end

function TargetData_mt:ByteOrder()
   return llvm.LLVMByteOrder(self.td)
end

function TargetData_mt:PointerSize()
   return llvm.LLVMPointerSize(self.td)
end

function TargetData_mt:IntPtrType()
   return Type(llvm.LLVMIntPtrType(self.td))
end

function TargetData_mt:SizeOfTypeInBits(ty)
   return llvm.LLVMSizeOfTypeInBits(self.td, ty.ty)
end

function TargetData_mt:StoreSizeOfType(ty)
   return llvm.LLVMStoreSizeOfType(self.td, ty.ty)
end

function TargetData_mt:ABISizeOfType(ty)
   return llvm.LLVMABISizeOfType(self.td, ty.ty)
end

function TargetData_mt:ABIAlignmentOfType(ty)
   return llvm.LLVMABIAlignmentOfType(self.td, ty.ty)
end

function TargetData_mt:CallFrameAlignmentOfType(ty)
   return llvm.LLVMCallFrameAlignmentOfType(self.td, ty.ty)
end

function TargetData_mt:PreferredAlignmentOfType(ty)
   return llvm.LLVMPreferredAlignmentOfType(self.td, ty.ty)
end

function TargetData_mt:PreferredAlignmentOfGlobal(val)
   return llvm.LLVMPreferredAlignmentOfGlobal(self.td, val.val)
end

function TargetData_mt:ElementAtOffset(struct_ty, offset)
   return llvm.LLVMElementAtOffset(self.td, struct_ty.ty, offset)
end

function TargetData_mt:OffsetOfElement(struct_ty, element)
   return llvm.LLVMOffsetOfElement(self.td, struct_ty.ty, element)
end

function TargetData_mt:delete()
   if self.td ~= nil then
      llvm.LLVMDisposeTargetData(self.td)
      self.td = nil
   end
end

TargetData_mt.__index = TargetData_mt
TargetData_mt.__gc = TargetData_mt.delete

local TargetData = ffi.metatype("struct zz_llvm_TargetData", TargetData_mt)

function M.CreateTargetData(string_rep)
   return TargetData(llvm.LLVMCreateTargetData(string_rep))
end

-- Target

ffi.cdef [[ struct zz_llvm_Target { LLVMTargetRef t; }; ]]

local Target_mt = {}

function Target_mt:GetTargetName()
   return ffi.string(llvm.LLVMGetTargetName(self.t))
end

function Target_mt:GetTargetDescription()
   return ffi.string(llvm.LLVMGetTargetDescription(self.t))
end

function Target_mt:TargetHasJIT()
   return llvm.LLVMTargetHasJIT(self.t) ~= 0
end

function Target_mt:TargetHasTargetMachine()
   return llvm.LLVMTargetHasTargetMachine(self.t) ~= 0
end

function Target_mt:TargetHasAsmBackend()
   return llvm.LLVMTargetHasAsmBackend(self.t) ~= 0
end

Target_mt.__index = Target_mt

local Target = ffi.metatype("struct zz_llvm_Target", Target_mt)

function M.GetTargetFromName(name)
   return Target(llvm.LLVMGetTargetFromName(name))
end

function M.GetTargetFromTriple(triple)
   local error_message = ffi.new("char*[1]")
   local t = ffi.new("LLVMTargetRef[1]")
   local rv = llvm.LLVMGetTargetFromTriple(triple, t, error_message)
   if rv ~= 0 then
      ef("LLVMGetTargetFromTriple() failed: %s", error_message[0])
   end
   return Target(t[0])
end

function M.GetDefaultTargetTriple()
   return ffi.string(llvm.LLVMGetDefaultTargetTriple())
end

-- TargetMachine

ffi.cdef [[ struct zz_llvm_TargetMachine { LLVMTargetMachineRef t; }; ]]

local TargetMachine_mt = {}

function TargetMachine_mt:GetTargetMachineTarget()
   return Target(llvm.LLVMGetTargetMachineTarget(self.t))
end

function TargetMachine_mt:GetTargetMachineTriple()
   return ffi.string(llvm.LLVMGetTargetMachineTriple(self.t))
end

function TargetMachine_mt:GetTargetMachineCPU()
   return ffi.string(llvm.LLVMGetTargetMachineCPU(self.t))
end

function TargetMachine_mt:GetTargetMachineFeatureString()
   return ffi.string(llvm.LLVMGetTargetMachineFeatureString(self.t))
end

function TargetMachine_mt:CreateTargetDataLayout()
   return TargetData(llvm.LLVMCreateTargetDataLayout(self.t))
end

function TargetMachine_mt:SetTargetMachineAsmVerbosity(verbose_asm)
   llvm.LLVMSetTargetMachineAsmVerbosity(self.t, LLVMBool(verbose_asm))
end

function TargetMachine_mt:TargetMachineEmitToFile(m, filename, codegen)
   local error_message = ffi.new("char*[1]")
   local rv = llvm.LLVMTargetMachineEmitToFile(self.t, m.m, filename, codegen, error_message)
   if rv ~= 0 then
      ef("LLVMTargetMachineEmitToFile() failed: %s", error_message[0])
   end
end

function TargetMachine_mt:TargetMachineEmitToMemoryBuffer(m, codegen)
   local error_message = ffi.new("char*[1]")
   local out_membuf = ffi.new("LLVMMemoryBufferRef[1]")
   local rv = llvm.LLVMTargetMachineEmitToMemoryBuffer(self.t, m.m, codegen, error_message, out_membuf)
   if rv ~= 0 then
      ef("LLVMTargetMachineEmitToMemoryBuffer() failed: %s", error_message[0])
   end
   return MemoryBuffer(out_membuf[0])
end

function TargetMachine_mt:DisposeTargetMachine()
   if self.t ~= nil then
      llvm.LLVMDisposeTargetMachine(self.t)
      self.t = nil
   end
end
TargetMachine_mt.delete = TargetMachine_mt.DisposeTargetMachine

TargetMachine_mt.__index = TargetMachine_mt
TargetMachine_mt.__gc = TargetMachine_mt.delete

local TargetMachine = ffi.metatype("struct zz_llvm_TargetMachine", TargetMachine_mt)

function M.CreateTargetMachine(t, triple, cpu, features, level, reloc, code_model)
   return TargetMachine(llvm.LLVMCreateTargetMachine(t, triple, cpu, features, level, reloc, code_model))
end

-- Type

ffi.cdef [[ struct zz_llvm_Type { LLVMTypeRef ty; }; ]]

local Type_mt = {}

function Type_mt:GetTypeKind()
   return llvm.LLVMGetTypeKind(self.ty)
end

function Type_mt:TypeIsSized()
   return llvm.LLVMTypeIsSized(self.ty)
end

function Type_mt:DumpType()
   llvm.LLVMDumpType(self.ty)
end

function Type_mt:__tostring()
   return DisposeMessage(llvm.LLVMPrintTypeToString(self.ty))
end

function Type_mt:GetUndef()
   return Value(llvm.LLVMGetUndef(self.ty))
end

function Type_mt:ConstNull()
   return Value(llvm.LLVMConstNull(self.ty))
end

function Type_mt:ConstAllOnes()
   return Value(llvm.LLVMConstAllOnes(self.ty))
end

function Type_mt:ConstPointerNull()
   return Value(llvm.LLVMConstPointerNull(self.ty))
end

function Type_mt:GetIntTypeWidth()
   return llvm.LLVMGetIntTypeWidth(self.ty)
end

function Type_mt:ArrayType(element_count)
   return Type(llvm.LLVMArrayType(self.ty, element_count))
end

function Type_mt:PointerType(address_space)
   return Type(llvm.LLVMPointerType(self.ty, address_space or 0))
end

function Type_mt:VectorType(element_count)
   return Type(llvm.LLVMVectorType(self.ty, element_count))
end

function Type_mt:ConstInt(n, sign_extend)
   return Value(llvm.LLVMConstInt(self.ty, n, LLVMBool(sign_extend)))
end

function Type_mt:ConstIntOfString(text, radix)
   return Value(llvm.LLVMConstIntOfString(self.ty, text, radix))
end

function Type_mt:ConstReal(n)
   return Value(llvm.LLVMConstReal(self.ty, n))
end

function Type_mt:ConstRealOfString(text)
   return Value(llvm.LLVMConstRealOfString(self.ty, text))
end

function Type_mt:ConstArray(vals)
   return Value(llvm.LLVMConstArray(self.ty, ValueRefArray(vals), #vals))
end

function Type_mt:ConstNamedStruct(vals)
   return Value(llvm.LLVMConstNamedStruct(self.ty, ValueRefArray(vals), #vals))
end

function Type_mt:AlignOf()
   return Value(llvm.LLVMAlignOf(self.ty))
end

function Type_mt:SizeOf()
   return Value(llvm.LLVMSizeOf(self.ty))
end

function Type_mt.__eq(lhs, rhs)
   return lhs.ty == rhs.ty
end

Type_mt.__index = Type_mt

local Type = ffi.metatype("struct zz_llvm_Type", Type_mt)

-- Value

ffi.cdef [[ struct zz_llvm_Value { LLVMValueRef val; }; ]]

local Value_mt = {}

function Value_mt:TypeOf()
   return Type(llvm.LLVMTypeOf(self.val))
end

function Value_mt:GetValueKind()
   return llvm.LLVMGetValueKind(self.val)
end

function Value_mt:GetValueName()
   return ffi.string(llvm.LLVMGetValueName(self.val))
end

function Value_mt:SetValueName(name)
   llvm.LLVMSetValueName(self.val, name)
end

function Value_mt:GetAlignment()
   return llvm.LLVMGetAlignment(self.val)
end

function Value_mt:SetAlignment(bytes)
   llvm.LLVMSetAlignment(self.val, bytes)
end

function Value_mt:DumpValue()
   llvm.LLVMDumpValue(self.val)
end

function Value_mt:__tostring()
   return ffi.string(llvm.LLVMPrintValueToString(self.val))
end

function Value_mt:ReplaceAllUsesWith(newval)
   llvm.LLVMReplaceAllUsesWith(self.val, newval.val)
end

function Value_mt:IsConstant()
   return llvm.LLVMIsConstant(self.val) ~= 0
end

function Value_mt:IsUndef()
   return llvm.LLVMIsUndef(self.val) ~= 0
end

function Value_mt:IsNull()
   return llvm.LLVMIsNull(self.val) ~= 0
end

function Value_mt:GetInitializer()
   return Value(llvm.LLVMGetInitializer(self.val))
end

function Value_mt:SetInitializer(constant_val)
   llvm.LLVMSetInitializer(self.val, constant_val.val)
end

function Value_mt:IsGlobalConstant()
   return llvm.LLVMIsGlobalConstant(self.val) ~= 0
end

function Value_mt:SetGlobalConstant(is_constant)
   llvm.LLVMSetGlobalConstant(self.val, LLVMBool(is_constant))
end

function Value_mt:IsExternallyInitialized()
   return llvm.LLVMIsExternallyInitialized(self.val) ~= 0
end

function Value_mt:SetExternallyInitialized(is_ext_init)
   llvm.LLVMSetExternallyInitialized(self.val, LLVMBool(is_ext_init))
end

function Value_mt:GetFunctionCallConv()
   return llvm.LLVMGetFunctionCallConv(self.val)
end

function Value_mt:SetFunctionCallConv(cc)
   llvm.LLVMSetFunctionCallConv(self.val, cc)
end

function Value_mt:GetLinkage()
   return llvm.LLVMGetLinkage(self.val)
end

function Value_mt:SetLinkage(linkage)
   llvm.LLVMSetLinkage(self.val, linkage)
end

function Value_mt.__eq(lhs, rhs)
   return lhs.val == rhs.val
end

Value_mt.__index = Value_mt

local Value = ffi.metatype("struct zz_llvm_Value", Value_mt)

-- Function

function M.FunctionType(return_type, param_types, is_var_arg)
   return Type(llvm.LLVMFunctionType(
                  return_type.ty,
                  TypeRefArray(param_types),
                  #param_types,
                  LLVMBool(is_var_arg)))
end

-- Module

ffi.cdef [[ struct zz_llvm_Module { LLVMModuleRef m; }; ]]

local Module_mt = {}

function Module_mt:GetModuleIdentifier()
   local size = ffi.new("size_t[1]")
   local ptr = llvm.LLVMGetModuleIdentifier(self.m, size)
   return ffi.string(ptr, size[0])
end

function Module_mt:SetModuleIdentifier(ident)
   llvm.LLVMSetModuleIdentifier(self.m, ident, #ident)
end

function Module_mt:GetDataLayoutStr()
   return ffi.string(llvm.LLVMGetDataLayoutStr(self.m))
end
Module_mt.GetDataLayout = Module_mt.GetDataLayoutStr

function Module_mt:SetDataLayout(triple)
   llvm.LLVMSetDataLayout(self.m, triple)
end

function Module_mt:GetTarget()
   return ffi.string(llvm.LLVMGetTarget(self.m))
end

function Module_mt:SetTarget(triple)
   llvm.LLVMSetTarget(self.m, triple)
end

function Module_mt:AddGlobal(ty, name)
   return Value(llvm.LLVMAddGlobal(self.m, ty, name))
end

function Module_mt:GetNamedGlobal(name)
   return Value(llvm.LLVMGetNamedGlobal(self.m, name))
end

function Module_mt:AddFunction(name, function_ty)
   return Value(llvm.LLVMAddFunction(self.m, name, function_ty.ty))
end
Module_mt.Function = Module_mt.AddFunction

function Module_mt:GetNamedFunction(name)
   return Value(llvm.LLVMGetNamedFunction(self.m, name))
end

function Module_mt:GetModuleDataLayout()
   return TargetData(llvm.LLVMGetModuleDataLayout(self.m))
end

function Module_mt:SetModuleDataLayout(td)
   llvm.LLVMSetModuleDataLayout(self.m, td.td)
end

function Module_mt:DumpModule()
   llvm.LLVMDumpModule(self.m)
end

function Module_mt:PrintModuleToFile(filename)
   local error_message = ffi.new("char*[1]")
   if llvm.LLVMPrintModuleToFile(self.m, filename, error_message) ~= 0 then
      ef("LLVMPrintModuleToFile(%s) failed: %s", filename, DisposeMessage(error_message[0]))
   end
end

function Module_mt:WriteBitcodeToFile(path)
   return llvm.LLVMWriteBitcodeToFile(self.m, path)
end

function Module_mt:WriteBitcodeToFD(fd, should_close, unbuffered)
   return llvm.LLVMWriteBitcodeToFD(self.m, fd,
                                    LLVMBool(should_close),
                                    LLVMBool(unbuffered))
end

function Module_mt:WriteBitcodeToMemoryBuffer()
   return MemoryBuffer(llvm.LLVMWriteBitcodeToMemoryBuffer(self.m))
end

function Module_mt:LinkModules(src)
   -- link src into self
   util.check_ok("LLVMLinkModules2", 0, llvm.LLVMLinkModules2(self.m, src.m))
end

function Module_mt:VerifyModule(failure_action)
   local out_message = ffi.new("char*[1]")
   local rv = llvm.LLVMVerifyModule(self.m, failure_action)
   if rv ~= 0 then
      ef("LLVMVerifyModule() failed: %s", ffi.string(out_message[0]))
   end
end

function Module_mt:__tostring()
   return DisposeMessage(llvm.LLVMPrintModuleToString(self.m))
end

function Module_mt.__eq(lhs, rhs)
   return lhs.m == rhs.m
end

function Module_mt:DisposeModule()
   if self.m ~= nil then
      llvm.LLVMDisposeModule(self.m)
      self.m = nil
   end
end
Module_mt.delete = Module_mt.DisposeModule

Module_mt.__index = Module_mt
Module_mt.__gc = Module_mt.delete

local Module = ffi.metatype("struct zz_llvm_Module", Module_mt)

-- Context

ffi.cdef [[ struct zz_llvm_Context { LLVMContextRef ctx; }; ]]

local Context_mt = {}

function Context_mt:ModuleCreateWithNameInContext(module_id)
   return Module(llvm.LLVMModuleCreateWithNameInContext(module_id, self.ctx))
end
Context_mt.Module = Context_mt.ModuleCreateWithNameInContext

function Context_mt:Int1Type()
   return Type(llvm.LLVMInt1TypeInContext(self.ctx))
end

function Context_mt:Int8Type()
   return Type(llvm.LLVMInt8TypeInContext(self.ctx))
end

function Context_mt:Int16Type()
   return Type(llvm.LLVMInt16TypeInContext(self.ctx))
end

function Context_mt:Int32Type()
   return Type(llvm.LLVMInt32TypeInContext(self.ctx))
end

function Context_mt:Int64Type()
   return Type(llvm.LLVMInt64TypeInContext(self.ctx))
end

function Context_mt:IntType(numbits)
   return Type(llvm.LLVMIntTypeInContext(self.ctx, numbits))
end

function Context_mt:HalfType()
   return Type(llvm.LLVMHalfTypeInContext(self.ctx))
end

function Context_mt:FloatType()
   return Type(llvm.LLVMFloatTypeInContext(self.ctx))
end

function Context_mt:DoubleType()
   return Type(llvm.LLVMDoubleTypeInContext(self.ctx))
end

function Context_mt:StructType(element_types, packed)
   return Type(llvm.LLVMStructTypeInContext(
                  self.ctx,
                  TypeRefArray(element_types),
                  #element_types,
                  LLVMBool(packed)))
end

function Context_mt:ConstString(str, dont_null_terminate)
   return Value(llvm.LLVMConstStringInContext(
                   self.ctx,
                   str, #str,
                   LLVMBool(dont_null_terminate)))
end

function Context_mt:ConstStruct(vals, packed)
   return Value(llvm.LLVMConstStructInContext(
                   self.ctx,
                   ValueRefArray(vals),
                   #vals,
                   LLVMBool(packed)))
end

function Context_mt:VoidType()
   return Type(llvm.LLVMVoidTypeInContext(self.ctx))
end

function Context_mt:LabelType()
   return Type(llvm.LLVMLabelTypeInContext(self.ctx))
end

function Context_mt:ParseBitCode(buf)
   local m = ffi.new("LLVMModuleRef[1]")
   local rv = llvm.LLVMParseBitcodeInContext2(self.ctx, buf, m)
   if rv ~= 0 then
      error("LLVMParseBitcodeInContext2() failed")
   end
   return Module(m[0])
end

function Context_mt:GetBitCodeModule(buf)
   local m = ffi.new("LLVMModuleRef[1]")
   local rv = llvm.LLVMGetBitcodeModuleInContext2(self.ctx, buf, m)
   if rv ~= 0 then
      error("LLVMGetBitcodeModuleInContext2() failed")
   end
   return Module(m[0])
end

function Context_mt:ParseIR(src)
   local m = ffi.new("LLVMModuleRef[1]")
   local out_message = ffi.new("char*[1]")
   local buf
   if type(src) == "string" then
      buf = M.CreateMemoryBufferWithMemoryRange(src, #src, nil, false)
   else
      buf = src
   end
   local rv = llvm.LLVMParseIRInContext(self.ctx, buf.buf, m, out_message)
   if rv ~= 0 then
      ef("LLVMParseIRInContext() failed: %s", ffi.string(out_message[0]))
   end
   return Module(m[0])
end

function Context_mt:ContextDispose()
   if self.ctx ~= nil then
      llvm.LLVMContextDispose(self.ctx)
      self.ctx = nil
   end
end
Context_mt.delete = Context_mt.ContextDispose

Context_mt.__index = Context_mt
Context_mt.__gc = Context_mt.delete

local Context = ffi.metatype("struct zz_llvm_Context", Context_mt)

function M.ContextCreate()
   return Context(llvm.LLVMContextCreate())
end
M.Context = M.ContextCreate

function M.ConstVector(vals)
   return Value(llvm.LLVMConstVector(ValueRefArray(vals), #vals))
end

function M.ConstGEP(const_val, const_indices)
   return Value(llvm.LLVMConstGEP(const_val,
                                  ValueRefArray(const_indices),
                                  #const_indices))
end

-- PassManager

ffi.cdef [[ struct zz_llvm_PassManager { LLVMPassManagerRef pm; }; ]]

local PassManager_mt = {}

function PassManager_mt:RunPassManager(m)
   util.check_ok("LLVMRunPassManager", 0,
                 llvm.LLVMRunPassManager(self.pm, m.m))
end

function PassManager_mt:delete()
   if self.pm ~= nil then
      llvm.LLVMDisposePassManager(self.pm)
      self.pm = nil
   end
end

PassManager_mt.__index = PassManager_mt
PassManager_mt.__gc = PassManager_mt.delete

local PassManager = ffi.metatype("struct zz_llvm_PassManager", PassManager_mt)

function M.CreateFunctionPassManagerForModule(m)
   return PassManager(llvm.LLVMCreateFunctionPassManagerForModule(m.m))
end
M.PassManager = M.CreateFunctionPassManagerForModule

function M.AddAnalysisPasses(t, pm)
   llvm.LLVMAddAnalysisPasses(t.t, pm.pm)
end

-- GenericValue

ffi.cdef [[ struct zz_llvm_GenericValue { LLVMGenericValueRef genval; }; ]]

local GenericValue_mt = {}

function GenericValue_mt:GenericValueIntWidth()
   return llvm.LLVMGenericValueIntWidth(self.genval)
end

function GenericValue_mt:GenericValueToInt(is_signed)
   return llvm.LLVMGenericValueToInt(self.genval, LLVMBool(is_signed))
end

function GenericValue_mt:GenericValueToPointer()
   return llvm.LLVMGenericValueToPointer(self.genval)
end

function GenericValue_mt:GenericValueToFloat(ty)
   return llvm.LLVMGenericValueToFloat(ty.ty, self.genval)
end

function GenericValue_mt:delete()
   if self.genval ~= nil then
      llvm.LLVMDisposeGenericValue(self.genval)
      self.genval = nil
   end
end

GenericValue_mt.__index = GenericValue_mt
GenericValue_mt.__gc = GenericValue_mt.delete

local GenericValue = ffi.metatype("struct zz_llvm_GenericValue", GenericValue_mt)

function M.CreateGenericValueOfInt(ty, n, is_signed)
   return GenericValue(llvm.LLVMCreateGenericValueOfInt(ty.ty, n, LLVMBool(is_signed)))
end

function M.CreateGenericValueOfPointer(p)
   return GenericValue(llvm.LLVMCreateGenericValueOfPointer(p))
end

function M.CreateGenericValueOfFloat(ty, n)
   return GenericValue(llvm.LLVMCreateGenericValueOfFloat(ty.ty, n))
end

-- MCJITCompilerOptions

function M.MCJITCompilerOptions(opts)
   local options = ffi.new("struct LLVMMCJITCompilerOptions")
   llvm.LLVMInitializeMCJITCompilerOptions(options, ffi.sizeof(options))
   if opts.OptLevel then
      options.OptLevel = opts.OptLevel
   end
   if opts.CodeModel then
      options.CodeModel = opts.CodeModel
   end
   if opts.NoFramePointerElim then
      options.NoFramePointerElim = LLVMBool(NoFramePointerElim)
   end
   if opts.EnableFastISel then
      options.EnableFastISel = LLVMBool(EnableFastISel)
   end
   if opts.MCJMM then
      options.MCJMM = opts.MCJMM
   end
   return options
end

-- ExecutionEngine

ffi.cdef [[ struct zz_llvm_ExecutionEngine { LLVMExecutionEngineRef ee; }; ]]

local ExecutionEngine_mt = {}

function ExecutionEngine_mt:RunStaticConstructors()
   llvm.LLVMRunStaticConstructors(self.ee)
end

function ExecutionEngine_mt:RunStaticDestructors()
   llvm.LLVMRunStaticDestructors(self.ee)
end

function ExecutionEngine_mt:RunFunctionAsMain(f, argc, argv, envp)
   argc = argc or 0
   local real_argv = ffi.new("const char*[?]", argc+1)
   if argc > 0 then
      assert(type(argv)=="table")
      for i=1,argc do
         real_argv[i-1] = argv[i]
      end
   end
   real_argv[argc] = nil -- not sure this sentinel is needed
   envp = envp or nil -- if supplied, caller must set it up
   return llvm.LLVMRunFunctionAsMain(self.ee, f.val, argc, real_argv, envp)
end

function ExecutionEngine_mt:RunFunction(f, args)
   return GenericValue(llvm.LLVMRunFunction(
                          self.ee, 
                          f.val, 
                          #args,
                          GenericValueRefArray(args)))
end

function ExecutionEngine_mt:FreeMachineCodeForFunction(f)
   llvm.LLVMFreeMachineCodeForFunction(self.ee, f.val)
end

function ExecutionEngine_mt:AddModule(m)
   llvm.LLVMAddModule(self.ee, m.m)
end

function ExecutionEngine_mt:FindFunction(name)
   local out_fn = ffi.new("LLVMValueRef[1]")
   local rv = llvm.LLVMFindFunction(self.ee, name, out_fn)
   if rv ~=0 then
      error("LLVMFindFunction(%s) failed", name)
   end
   return Value(out_fn[0])
end

function ExecutionEngine_mt:RecompileAndRelinkFunction(fn)
   llvm.LLVMRecompileAndRelinkFunction(self.ee, fn.val)
end

function ExecutionEngine_mt:GetExecutionEngineTargetData()
   return TargetData(llvm.LLVMGetExecutionEngineTargetData(self.ee))
end

function ExecutionEngine_mt:GetExecutionEngineTargetMachine()
   return TargetMachine(llvm.LLVMGetExecutionEngineTargetMachine(self.ee))
end

function ExecutionEngine_mt:AddGlobalMapping(global_val, addr)
   llvm.LLVMAddGlobalMapping(self.ee, global_val.val, ffi.cast("void*", addr))
end

function ExecutionEngine_mt:GetPointerToGlobal(global_val)
   return llvm.LLVMGetPointerToGlobal(self.ee, global_val.val)
end

function ExecutionEngine_mt:GetGlobalValueAddress(name)
   return llvm.LLVMGetGlobalValueAddress(self.ee, name)
end

function ExecutionEngine_mt:GetFunctionAddress(name)
   return ffi.cast("void*", llvm.LLVMGetFunctionAddress(self.ee, name))
end

function ExecutionEngine_mt:DisposeExecutionEngine()
   if self.ee ~= nil then
      llvm.LLVMDisposeExecutionEngine(self.ee)
      self.ee = nil
   end
end
ExecutionEngine_mt.delete = ExecutionEngine_mt.DisposeExecutionEngine

ExecutionEngine_mt.__index = ExecutionEngine_mt
ExecutionEngine_mt.__gc = ExecutionEngine_mt.delete

local ExecutionEngine = ffi.metatype("struct zz_llvm_ExecutionEngine", ExecutionEngine_mt)

function M.CreateExecutionEngineForModule(m)
   local out_ee = ffi.new("LLVMExecutionEngineRef[1]")
   local out_error = ffi.new("char*[1]")
   local rv = llvm.LLVMCreateExecutionEngineForModule(out_ee, m.m, out_error)
   if rv ~= 0 then
      ef("LLVMCreateExecutionEngineForModule() failed: %s", ffi.string(out_error[0]))
   end
   return ExecutionEngine(out_ee[0])
end

function M.CreateInterpreterForModule(m)
   local out_interp = ffi.new("LLVMExecutionEngineRef[1]")
   local out_error = ffi.new("char*[1]")
   local rv = llvm.LLVMCreateInterpreterForModule(out_interp, m.m, out_error)
   if rv ~= 0 then
      ef("LLVMCreateInterpreterForModule() failed: %s", ffi.string(out_error[0]))
   end
   return ExecutionEngine(out_interp[0])
end

function M.CreateJITCompilerForModule(m, opt_level)
   local out_jit = ffi.new("LLVMExecutionEngineRef[1]")
   local out_error = ffi.new("char*[1]")
   local rv = llvm.LLVMCreateJITCompilerForModule(out_jit, m.m, opt_level, out_error)
   if rv ~= 0 then
      ef("LLVMCreateJITCompilerForModule() failed: %s", ffi.string(out_error[0]))
   end
   return ExecutionEngine(out_jit[0])
end

function M.CreateMCJITCompilerForModule(m, options)
   local out_jit = ffi.new("LLVMExecutionEngineRef[1]")
   local out_error = ffi.new("char*[1]")
   local rv = llvm.LLVMCreateMCJITCompilerForModule(out_jit, m.m, options, ffi.sizeof(options), out_error)
   if rv ~= 0 then
      ef("LLVMCreateMCJITCompilerForModule() failed: %s", ffi.string(out_error[0]))
   end
   return ExecutionEngine(out_jit[0])
end

--

return setmetatable(M, { __index = llvm })
