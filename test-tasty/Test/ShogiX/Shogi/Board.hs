module Test.ShogiX.Shogi.Board where
import           RIO
import qualified RIO.Map                       as Map
import qualified RIO.Set                       as Set
import           Test.Tasty
import           Test.Tasty.Hspec
import           ShogiX.Shogi.Types
import qualified ShogiX.Shogi.Board            as Board

{-# ANN module "HLint: ignore Use camelCase" #-}
spec_movables :: Spec
spec_movables = describe "movables" $ do
  describe "将棋盤が空の場合"
    $          it "空を返す"
    $          Board.movables Black (Board Map.empty)
    `shouldBe` Movables Map.empty
  describe "将棋盤に駒がある場合"
    $          it "駒ごとの可動範囲を返す"
    $          Board.movables
                 Black
                 (Board
                   (Map.fromList
                     [ ((F5, R5), Piece Black Pawn)
                     , ((F5, R9), Piece Black Gold)
                     , ((F5, R1), Piece White Pawn)
                     ]
                   )
                 )
    `shouldBe` Movables
                 (Map.fromList
                   [ ((F5, R5), Movable (Map.fromList [((F5, R4), No)]))
                   , ( (F5, R9)
                     , Movable
                       (Map.fromList
                         [ ((F6, R8), No)
                         , ((F5, R8), No)
                         , ((F4, R8), No)
                         , ((F4, R9), No)
                         , ((F6, R9), No)
                         ]
                       )
                     )
                   ]
                 )
