import           RIO
import           Test.DocTest                   ( doctest )

main :: IO ()
main = doctest ["-XNoImplicitPrelude", "src"]
