{-| Module      :  TS_Parser
    License     :  GPL

    Maintainer  :  helium@cs.uu.nl
    Stability   :  experimental
    Portability :  portable
    
    The parser of a .type file.
	
	(directives based on "Scripting the Type Inference Process", ICFP 2003) 
-}

module Helium.StaticAnalysis.Directives.TS_Parser where
 
-- UHA
import Helium.Syntax.UHA_Syntax
import Helium.Syntax.UHA_Utils (nameFromString)
import qualified Helium.Syntax.UHA_Pretty as PP
-- Typing strategies
import Helium.StaticAnalysis.Directives.TS_Syntax
import Helium.Parser.Lexer (Token, Lexeme)
import Helium.Parser.ParseLibrary hiding (satisfy)
import Helium.Parser.Parser (exp0, type_, atype)
import qualified Helium.Parser.ResolveOperators as ResolveOperators
import Text.ParserCombinators.Parsec
import Top.Types.Classes()
import Data.List (intersperse, intercalate)
import Helium.Parser.OperatorTable
import Helium.Utils.Utils (internalError)

parseTypingStrategies :: OperatorTable -> String -> [Token] -> Either ParseError TypingStrategies
parseTypingStrategies operatorTable filename toks = 
   runHParser (many parseTypingStrategy) filename toks True {- wait for EOF -}
  
  where

   parseTypingStrategy :: HParser TypingStrategy
   parseTypingStrategy = 
      do lexSIBLINGS
         names <- commas1 (var <|> varop <|> con <|> conop <|> special)
         lexSEMI         
         return (TypingStrategy_Siblings names)
      <|>   
      do    lexNEVER
            predClass <- con
            predType <- atype
            lexCOL
            message <- lexString
            return (TypingStrategy_Never predClass predType message)
      <|>
      do    lexCLOSE
            className <- con
            lexCOL
            message <- lexString
            return (TypingStrategy_Close className message)
      <|>
      do    lexDISJOINT
            class1 <- con
            class2 <- con
            lexCOL
            message <- lexString
            return (TypingStrategy_Disjoint [class1, class2] message)
      <|>
      do    lexDEFAULT
            className <- con
            lexLPAREN
            types <- commas type_
            lexRPAREN
            return (TypingStrategy_Default className types)
      <|>
      do typerule    <- parseTypeRule 
         constraints <- many parseConstraint
         lexSEMI  
         return (TypingStrategy_TypingStrategy typerule constraints)
      
   parseTypeRule :: HParser TypeRule
   parseTypeRule =         
      do judgements <- many1 parseJudgement
         lexSEMI 
         let (premises, conclusion) = (init judgements, last judgements)
         return (TypeRule_TypeRule (map judgementToSimpleJudgement premises) conclusion)

   parseJudgement :: HParser Judgement
   parseJudgement =         
      do expression <- exp0 
         lexCOLCOL
         exprType   <- type_
         lexSEMI      
         let resolvedExpression = ResolveOperators.expression operatorTable expression
         return (Judgement_Judgement resolvedExpression exprType)     

   parseConstraint :: HParser UserStatement
   parseConstraint =
      do -- enter a new phase
         lexPHASE
         phase <- fmap read lexInt
         return (UserStatement_Phase (fromInteger phase))
      <|>
      do -- constraint set of meta-variable
         lexCONSTRAINTS         
         theName <- varid
         return (UserStatement_MetaVariableConstraints theName)
      <|> 
      parseUserConstraint
      
   parseUserConstraint :: HParser UserStatement
   parseUserConstraint = try pPredicate <|> pEquality
   
    where
     pPredicate =
        do -- user predicate
           predClass <- con
           predType <- atype
           lexCOL
           msgLines  <- many1 lexString
           let message = concat (intersperse "\n" msgLines)
           return (UserStatement_Pred predClass predType message)
           
     pEquality =
        do -- user equality constraint
           leftType  <- type_
           lexASGASG
           rightType <- type_
           lexCOL
           msgLines  <- many1 lexString
           let message = intercalate "\n" msgLines
           return (UserStatement_Equal leftType rightType message)

special ::  GenParser (SourcePos,Lexeme) SourcePos Name
special =  do lexCOL    ; return (nameFromString ":")
       <|> do lexASGASG ; return (nameFromString "==")

judgementToSimpleJudgement :: Judgement -> SimpleJudgement
judgementToSimpleJudgement judgement = 
   case judgement of
      Judgement_Judgement (Expression_Variable _ theName) tp 
         -> SimpleJudgement_SimpleJudgement theName tp
      Judgement_Judgement expression                   _ 
         -> internalError "TS_Parser.hs" "judgementToSimpleJudgement" 
               ("the following expression should have been a meta-variable: "++showExpression expression)
      
showExpression :: Expression -> String
showExpression e = show $ PP.text_Syn_Expression $ PP.wrap_Expression (PP.sem_Expression e) PP.Inh_Expression
