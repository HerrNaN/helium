{-| Module      :  LexerToken
    License     :  GPL

    Maintainer  :  helium@cs.uu.nl
    Stability   :  experimental
    Portability :  portable
-}

module Helium.Parser.LexerToken where

import Text.ParserCombinators.Parsec.Pos(SourcePos)
import qualified Helium.Utils.Texts as Texts

type Token      = (SourcePos,Lexeme)

data Lexeme     
    = LexChar            String
    | LexString          String
    | LexInt             String
    | LexFloat           String
    
    | LexVar             String
    | LexVarSym          String
    | LexCon             String
    | LexConSym          String
    | LexQual            String

    | LexKeyword         String
    | LexResVarSym       String
    | LexResConSym       String
    | LexSpecial         Char

    | LexFeedback        String
    | LexCaseFeedback    String
    | LexMustUse
    | LexHole
    | LexNamedHole       String
    | LexEta             Char

    | LexInsertedOpenBrace  -- { inserted because of layout
    | LexInsertedCloseBrace -- }
    | LexInsertedSemicolon  -- ;

    | LexEOF
    deriving Eq

instance Show Lexeme where
    show x = case x of
        LexChar    c        -> Texts.parserCharacterLiteral      ++ " '" ++ c      ++ "'"
        LexString  s        -> Texts.parserStringLiteral         ++ " \""++ s      ++ "\""
        LexInt     i        -> Texts.parserIntegerLiteral        ++ " '" ++ i      ++ "'"
        LexFloat   f        -> Texts.parserFloatLiteral          ++ " '" ++ f      ++ "'"

        LexVar     n        -> Texts.parserVariable              ++ " '" ++ n      ++ "'"
        LexVarSym  o        -> Texts.parserOperator              ++ " '" ++ o      ++ "'"
        LexCon     c        -> Texts.parserConstructor           ++ " '" ++ c      ++ "'"
        LexConSym  o        -> Texts.parserConstructorOperator   ++ " '" ++ o      ++ "'"
        LexQual    q        -> Texts.parserQualified             ++ " '" ++ q      ++ "'"
        
        LexKeyword kwd      -> Texts.parserKeyword ++ " '" ++ kwd ++ "'"
        LexResVarSym s      -> "'" ++ s ++ "'"
        LexResConSym s      -> "'" ++ s ++ "'"
        LexSpecial c        -> "'" ++ [c] ++ "'"
        
        LexFeedback f       -> "Feedback \"" ++ f ++ "\""
        LexCaseFeedback f   -> "Case feedback \"" ++ f ++ "\""
        LexMustUse          -> "Must Use"
        LexHole             -> "Hole"
        LexNamedHole h      -> "Hole \"" ++ h ++ "\""
        LexEta n            -> "Eta \"" ++ n : "\""
        
        LexInsertedOpenBrace  -> Texts.parserInsertedLBrace 
        LexInsertedCloseBrace -> Texts.parserEndOfBlock
        LexInsertedSemicolon  -> Texts.parserNextInBlock
                        
        LexEOF              -> Texts.parserEndOfFile
        
lexemeLength :: Lexeme -> Int
lexemeLength l = case l of
    LexChar            s     -> length s + 2 -- count the quotes, too
    LexString          s     -> length s + 2
    LexInt             s     -> length s
    LexFloat           s     -> length s

    LexVar             s     -> length s
    LexVarSym          s     -> length s
    LexCon             s     -> length s
    LexConSym          s     -> length s
    LexQual            s     -> length s + 1 -- count the dot that is not in the string

    LexHole                  -> 1
    LexNamedHole       s     -> 1 + length s

    LexSpecial         _     -> 1
    LexKeyword         s     -> length s
    LexResVarSym       s     -> length s
    LexResConSym       s     -> length s
    _                        -> 0
