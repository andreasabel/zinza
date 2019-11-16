module Zinza.Errors where

import Control.Exception (Exception (..), throwIO)

import Zinza.Type
import Zinza.Var
import Zinza.Pos

errorLoc :: Loc -> String -> String
errorLoc l str = "Error at " ++ displayLoc l ++ ": " ++ str

-------------------------------------------------------------------------------
-- ParseError
-------------------------------------------------------------------------------

newtype ParseError = ParseError String
  deriving (Show)

instance Exception ParseError where
    displayException (ParseError err) = err

-------------------------------------------------------------------------------
-- CompileError
-------------------------------------------------------------------------------

data CompileError
    = UnboundTopLevelVar Loc Var
    | ARuntimeError RuntimeError
  deriving (Show)

instance Exception CompileError where
    displayException (UnboundTopLevelVar loc var) = errorLoc loc $
        "unbound variable '" ++ var ++ "'"
    displayException (ARuntimeError err) =
        displayException err


-------------------------------------------------------------------------------
-- CompileOrParseError
-------------------------------------------------------------------------------

data CompileOrParseError
    = ACompileError CompileError
    | AParseError ParseError
  deriving (Show)

instance Exception CompileOrParseError where
    displayException (ACompileError err) = displayException err
    displayException (AParseError err)   = displayException err

-------------------------------------------------------------------------------
-- RuntimeError
-------------------------------------------------------------------------------

data RuntimeError
    = NotBool Loc Ty
    | NotString Loc Ty
    | NotRecord Loc Ty
    | NotList Loc Ty
    | FieldNotInRecord Loc Var Ty
  deriving Show

instance Exception RuntimeError where
    displayException (NotBool loc ty) = errorLoc loc $
        "Not a bool " ++ displayTy ty
    displayException (NotString loc ty) = errorLoc loc $
        "Not a string " ++ displayTy ty
    displayException (NotRecord loc ty) = errorLoc loc $
        "Not a record " ++ displayTy ty
    displayException (NotList loc ty) = errorLoc loc $
        "Not a list " ++ displayTy ty
    displayException (FieldNotInRecord loc var ty) = errorLoc loc $
        "Field '" ++ var ++ "' isn't in a record of type " ++ displayTy ty

-- | Class representing errors containing 'RuntimeError's.
--
-- Without bugs, compiled template should not throw any 'RuntimeError's,
-- as they are prevented statically, i.e. reported already as 'CompileError's.
--
class    AsRuntimeError e where asRuntimeError :: RuntimeError -> e
instance AsRuntimeError RuntimeError where asRuntimeError = id
instance AsRuntimeError CompileError where asRuntimeError = ARuntimeError

class Monad m => ThrowRuntime m where
    throwRuntime ::  RuntimeError -> m a

instance AsRuntimeError e => ThrowRuntime (Either e) where
    throwRuntime = Left . asRuntimeError

instance ThrowRuntime IO where
    throwRuntime = throwIO
