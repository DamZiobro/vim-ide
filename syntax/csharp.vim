" Vim syntax file
" Language:	C#
" Maintainer:	Heath Stewart <clubstew@hotmail.com>
" Last change:	2002-07-16

" Notice: folding has been added for #region...#endregion regions

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

syn match csharpError "[\\`]"
syn match csharpError "<<<\|\.\.\|=>\|<>\|||=\|&&=\|[^-]->\|\*\/"
syn keyword csharpConditional 	if else switch case default
syn keyword csharpRepeat	while for foreach do goto in
syn keyword csharpBoolean	true false
syn keyword csharpConst		null
syn keyword csharpTypedef	this base
syn match csharpOperator "{\|}\|\[\|\]\|(\|)\|-\|--\|+\|++\|=\|==\|!=\|<\|<=\|<<\|<<<\|>>\|>>>\|>=\|>\|&\|&&\|&=\|||\||\||=\|\\\|\\=\|\*\|\*=\|->\|%\|%=\|;\|,\|\.\|+=\|-=" 	
syn keyword csharpDirectional	out ref
syn keyword csharpType		bool byte char decimal double enum float int long sbyte short sizeof string uint ulong ushort void 
syn keyword csharpStatement	return  internal typeof lock new operator object
syn keyword csharpClass		class interface namespace struct override
syn keyword csharpProperties	get set add remove
syn keyword csharpException	try catch throw finally 
syn keyword csharpScope		public private protected abstract
syn keyword csharpBranch          break continue nextgroup=csharpUserLabelRef skipwhite
syn match   csharpUserLabelRef    "\k\+" contained
syn keyword csharpTypecast	as is
syn keyword csharpTypeConvertDecl	explicit implicit
syn keyword csharpStorageClass	static const delegate event extern fixed checked  unchecked sealed stackalloc virtual readonly unsafe params
syn keyword csharpExternal	namespace using
syn keyword csharpPreproc	#if #else #elif #endif #define #undef #warning #error #line #region #endregion

syn keyword csharpSystemClass   AccessException Activator AppDomain AppDomainFlags AppDomainUnloadedException AppDomainUnloadInProgressException ApplicationException ArgumentException ArgumentNullException ArgumentOutOfRangeException ArithmeticException Array 
syn keyword csharpSystemClass   ArrayTypeMismatchException Attribute AttributeUsageAttribute BadImageFormatException BitConverter Buffer CallContext CLSCompliantAttribute Console ContextBoundObject ContextMarshalException ContextStaticAttribute   Convert
syn keyword csharpSystemClass  CoreException DBNull Delegate DivideByZeroException DuplicateWaitObjectException Empty EntryPointNotFoundException Enum Environment EventArgs Exception ExecutionEngineException FieldAccessException FlagsAttribute Bitfeilds
syn keyword csharpSystemClass FormatException IndexOutOfRangeException InvalidCastException InvalidOperationException LocalDataStore LocalDataStoreMgr LocalDataStoreSlot LogicalCallContext MarshalByRefObject Math MethodAccessException MissingFieldException
syn keyword csharpSystemClass MissingMemberException MissingMethodException MulticastDelegate MulticastNotSupportedException NonSerializedAttribute NotFiniteNumberException NotImplementedException NotSupportedException NullReferenceException Object ObsoleteAttribute
syn keyword csharpSystemClass OperatingSystem OutOfMemoryException OverflowException ParamArrayAttribute Radix Random RankException SerializableAttribute StackOverflowException String SystemException ThreadStaticAttribute TimeZone Type TypeInitializationException
syn keyword csharpSystemClass TypeLoadException TypeUnloadedException UnhandledExceptionEvent Value ValueType Version WeakReference WeakReferenceException 

syn keyword csharpSystemInterface IAsyncResult   ICloneable IComparable IConvertible ICustomFormatter IFormattable ILogicalThreadAffinative IServiceObjectProvider
syn keyword csharpSystemValueType  ArgIterator Boolean Byte Char Currency DateTime Decimal Double Guid Int16 Int32 Int64 ParamArray RuntimeArgumentHandle RuntimeFieldHandle RuntimeMethodHandle RuntimeTypeHandle SByte Single TimeSpan TypedReference UInt16 UInt32 UInt64 Void

syn keyword csharpSystemDelegate  AsyncCallback EventHandler UnhandledExceptionEventHandler
syn keyword csharpSystemEnum 	AttributeTargets PlatformID TypeCode

syn match   csharpSpecialError     contained "\\."
syn match   csharpSpecialCharError contained "[^']"
syn match   csharpSpecialChar      contained "\\\([4-9]\d\|[0-3]\d\d\|[\"\\'ntbrf]\|u\x\{4\}\)"
syn region   csharpString          start=+"+ end=+"+ end=+$+ contains=csharpSpecialChar,csharpSpecialError,@Spell
syn match   csharpStringError      +"\([^"\\]\|\\.\)*$+
syn match   csharpCharacter        "'[^']*'" contains=csharpSpecialChar,csharpSpecialCharError
syn match   csharpCharacter        "'\\''" contains=csharpSpecialChar
syn match   csharpCharacter        "'[^\\]'"
syn match   csharpNumber           "\<\(0[0-7]*\|0[xX]\x\+\|\d\+\)[lL]\=\>"
syn match   csharpNumber           "\(\<\d\+\.\d*\|\.\d\+\)\([eE][-+]\=\d\+\)\=[fFdD]\="
syn match   csharpNumber           "\<\d\+[eE][-+]\=\d\+[fFdD]\=\>"
syn match   csharpNumber           "\<\d\+\([eE][-+]\=\d\+\)\=[fFdD]\>"

" unicode characters
syn match   csharpSpecial "\\u\d\{4\}"

syn cluster csharpTop add=csharpString,csharpCharacter,csharpNumber,csharpSpecial,csharpStringError

" Comments
syn keyword csharpTodo             contained TODO FIXME XXX
syn region  csharpCommentString    contained start=+"+ end=+"+ end=+$+ end=+\*/+me=s-1,he=s-1 contains=csharpSpecial,csharpCommentStar,csharpSpecialChar,@Spell
syn region  csharpComment2String   contained start=+"+  end=+$\|"+  contains=csharpSpecial,csharpSpecialChar,@Spell
syn match   csharpCommentCharacter contained "'\\[^']\{1,6\}'" contains=csharpSpecialChar
syn match   csharpCommentCharacter contained "'\\''" contains=csharpSpecialChar
syn match   csharpCommentCharacter contained "'[^\\]'"
syn region  csharpComment          start="/\*"  end="\*/" contains=csharpCommentString,csharpCommentCharacter,csharpNumber,csharpTodo,@Spell
syn match   csharpCommentStar      contained "^\s*\*[^/]"me=e-1
syn match   csharpCommentStar      contained "^\s*\*$"
syn match   csharpLineComment      "//.*" contains=csharpComment2String,csharpCommentCharacter,csharpNumber,csharpTodo,@Spell

" Folding
function! CSharpFoldText(add)
	let line = getline(v:foldstart + a:add)
	let sub = substitute(line, '#region\s', '', 'i')
	let ts = &tabstop
	let text = ""
	while (l:ts > 0)
		let text = text . v:folddashes[0]
		let ts = ts - 1
	endwhile
	return substitute(sub, "\t", text, "g")
endfunction

syn region csharpRegionFold start="#region" end="#endregion" transparent fold
syn sync fromstart
set foldmethod=syntax foldcolumn=2 foldtext=CSharpFoldText(0)

hi link csharpCommentString csharpString
hi link csharpComment2String csharpString
hi link csharpCommentCharacter csharpCharacter

if !exists("did_csharp_syntax_inits")
    let did_csharp_syntax_inits=1
    hi link csharpConditional Conditional
    hi link csharpError	Error
    hi link csharpRepeat Repeat
    hi link csharpBoolean Boolean
    hi link csharpConst Constant
    hi link csharpTypedef Typedef
    hi link csharpOperator Operator
    hi link csharpDirectional Operator
    hi link csharpType	Type
    hi link csharpStatement statement
    hi link csharpClass Type
    hi link csharpException Exception
    hi link csharpScope	Statement
    hi link csharpBranch Keyword
    hi link csharpUserLabelRef label
    hi link csharpTypecast statement
    hi link csharpStorageClass StorageClass
    hi link csharpExternal preproc
    hi link csharpPreproc preproc
    hi link csharpSpecialError error
    hi link csharpString string
    hi link csharpCharacter	string
    hi link csharpComment Comment
    hi link csharpLineComment Comment
	hi link csharpTodo Todo
    hi link csharpProperties Operator
    hi link csharpTypeConvertDecl Operator
    hi link csharpSystemClass  StorageClass
    hi link csharpSystemInterface Statement
    hi link csharpSystemValueType Type
    hi link csharpSystemDelegate Statement
    hi link csharpSystemEnum  statement
    hi csharpProperties gui=italic 
endif
let b:current_syntax="csharp"
