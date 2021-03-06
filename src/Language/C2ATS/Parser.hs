module Language.C2ATS.Parser
       ( parseMkGlobal
       , GlobalDecls
       ) where

import System.IO
import Control.Arrow      hiding ((<+>))
import Data.List
import Language.C
import Language.C.Analysis
import Language.C.System.GCC

parseMkGlobal :: String -> [String] -> FilePath -> IO ([FilePath], GlobalDecls)
parseMkGlobal gcc opts input_file = do
  let compiler = newGCC gcc
  ast <- parseCFile compiler Nothing opts input_file >>= checkResult "[parsing]"
  (globals, warnings) <- (runTrav_ >>> checkResult "[analysis]") $ analyseAST ast
  mapM_ (hPutStrLn stderr . show) warnings
  return (filesInAST ast, globals)
  where
    checkResult :: (Show a) => String -> (Either a b) -> IO b
    checkResult label = either (error . (label++) . show) return

filesInAST :: CTranslUnit -> [FilePath]
filesInAST (CTranslUnit ds n) =
  delete "" . nub $ map (maybe "" id) (fileOfNode n : map fileOfNode ds)
