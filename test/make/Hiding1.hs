import Prelude hiding (map)
import Hiding2 hiding (x, y)
 --TODO: statische error bij verbergen show functie
x, y :: Int
x = 3
y = 4

map :: Num a => [a] -> a
map xs = sum xs

main :: (Int, String)
main = ( map [x,y,z] -- should be 307
       , show X -- show functions, types and constructors may not be hidden
       )
