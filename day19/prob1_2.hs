import qualified Data.Map as Map
import Data.Either (fromRight)
import Data.Function ((&))
import Data.Maybe (catMaybes, fromJust)
import Data.Tuple (swap)
-- import Debug.Trace
import Text.Parsec
import Text.Parsec.String

data Rule = Rule {
  partName :: String,
  op :: Char,
  number :: Int,
  nextWfName :: String
} deriving (Show)

type RuleOrNext = Either Rule String

nameParser :: Parser String
nameParser = many1 letter

ruleParser :: Parser Rule
ruleParser = do
  partName <- nameParser
  op <- oneOf "<>"
  number <- read <$> many1 digit
  char ':'
  nextWorkflowName <- nameParser
  return $ Rule partName op number nextWorkflowName

ruleOrNextParser :: Parser RuleOrNext
ruleOrNextParser = (Left <$> try ruleParser) <|> (Right <$> try nameParser)

type Workflow = (String, [RuleOrNext])

workflowParser :: Parser Workflow
workflowParser = do
  wfName <- nameParser
  char '{'
  rules <- ruleOrNextParser `sepBy` char ','
  char '}'
  return (wfName, rules)

-- | map of ratings and sum of ratings
data Part = Part (Map.Map String Int) Int
  deriving (Show)

ratingParser :: Parser (String, Int)
ratingParser = do
  name <- nameParser
  char '='
  number <- read <$> many1 digit
  return (name, number)

partParser :: Parser Part
partParser = do
  char '{'
  ratings <- ratingParser `sepBy` char ','
  char '}'
  return $ Part (Map.fromList ratings) (ratings & map snd & sum) -- same as (sum . map snd $ ratings)

programParser :: Parser ([Workflow], [Part])
programParser = do
  workflows <- workflowParser `endBy` endOfLine <* endOfLine
  parts <- partParser `sepEndBy` endOfLine
  return (workflows, parts)

type WorkflowMap = Map.Map String [RuleOrNext]
type RatingMap = Map.Map String Int

-- | AoC input is always valid
mustGet :: forall k a. Ord k => k -> Map.Map k a -> a
mustGet key m = fromJust $ Map.lookup key m

applyRule :: RatingMap -> String -> RuleOrNext -> String
-- if the last rule output is empty, apply this one
applyRule partRatings "" rule =
  case rule of
    Left Rule {partName = partName, op = op, number = number, nextWfName = wfName} ->
      let rating = mustGet partName partRatings in
      case op of
        '<' -> if rating < number then wfName else ""
        '>' -> if rating > number then wfName else ""
    Right wfName -> wfName
-- or there is already a result, pass through
applyRule _ wfName _ = wfName

applyWorkflow :: WorkflowMap -> String -> Part -> Maybe Int
applyWorkflow wfMap wfName part =
  let wfRules = mustGet wfName wfMap
      Part partRatings partScore = part in
  case (foldl (applyRule partRatings) "" wfRules) of
    "A" -> Just partScore
    "R" -> Nothing
    nextWf -> applyWorkflow wfMap nextWf part

-- | part 2
type Range = (Int, Int)
type RangesMap = (Map.Map String [Range])

sumRanges :: [Range] -> Int
sumRanges ranges = sum $ map (\(lower, upper) -> upper - lower + 1) ranges

combinationsFromRanges :: [[Range]] -> Int
combinationsFromRanges rangesList = product $ map sumRanges rangesList

-- | returns matched and not matched ranges
splitRanges :: [Range] -> Char -> Int -> ([Range], [Range])
splitRanges ranges '<' value =
  foldl 
    (\(smallerRanges, largerRanges) -> \(lower, upper) ->
      case value of
        n | n <= lower -> (smallerRanges, largerRanges ++ [(lower, upper)])
          | n <= upper -> (smallerRanges ++ [(lower, n - 1)], [(n, upper)])
          | otherwise -> (smallerRanges ++ [(lower, upper)], []))
    ([], [])
    ranges
splitRanges ranges '>' value =
  -- largerRanges are the matched ones, hence the swap
  swap $ foldr (\(lower, upper) -> \(smallerRanges, largerRanges) ->
      case value of
        n | n > upper -> (smallerRanges, (lower, upper) : largerRanges)
          | n > lower -> ([(lower, n)], (n + 1, upper) : largerRanges)
          | otherwise -> ([], (lower, upper) : largerRanges))
    ([], [])
    ranges

applyRules :: RangesMap -> WorkflowMap -> [RuleOrNext] -> Int
applyRules rangesMap wfMap (rule:restRules) =
  case rule of
    Left Rule {partName = partName, op = op, number = number, nextWfName = nextWfName} ->
      let ranges = mustGet partName rangesMap
          (matched, notMatched) = splitRanges ranges op number
          matchedRangesMap = Map.insert partName matched rangesMap
          notMatchedRangesMap = Map.insert partName notMatched rangesMap in
            (combinations matchedRangesMap wfMap nextWfName) + (applyRules notMatchedRangesMap wfMap restRules)
    Right nextWfName -> combinations rangesMap wfMap nextWfName

combinations :: RangesMap -> WorkflowMap -> String -> Int
combinations _ _ "R" = 0
combinations partRanges _ "A" = combinationsFromRanges $ Map.elems partRanges
combinations partRanges wfMap wfName = applyRules partRanges wfMap (mustGet wfName wfMap)

main :: IO ()
main = do
  contents <- getContents
  let (workflows, parts) = fromRight (error "parse error") (parse programParser "" contents)
      wfMap = Map.fromList workflows
      total = sum $ catMaybes (map (applyWorkflow wfMap "in") parts)
      rangesMap = Map.fromList $ zip ["x", "m", "a", "s"] (replicate 4 [(1, 4000)])
      numCombinations = combinations rangesMap wfMap "in"
  -- print $ workflows
  -- print $ parts
  print $ total
  print $ numCombinations
