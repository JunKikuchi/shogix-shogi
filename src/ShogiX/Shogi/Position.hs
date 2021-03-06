module ShogiX.Shogi.Position
  ( hirate
  , positionEq
  , move
  , ShogiX.Shogi.Position.drop
  , consumeTime
  , checked
  , mate
  , movables
  , droppables
  )
where

import           RIO
import qualified RIO.Map                       as Map
import qualified RIO.Set                       as Set
import           ShogiX.Clocks                  ( Clocks
                                                , Sec
                                                )
import qualified ShogiX.Clocks                 as Clocks
import           ShogiX.Shogi.Types
import qualified ShogiX.Shogi.Color            as Color
import qualified ShogiX.Shogi.Board            as Board
import qualified ShogiX.Shogi.Stands           as Stands
import qualified ShogiX.Shogi.Movable          as Movable
import qualified ShogiX.Shogi.Movables         as Movables
import qualified ShogiX.Shogi.Droppable        as Droppable
import qualified ShogiX.Shogi.Droppables       as Droppables

{-# ANN module "HLint: ignore Reduce duplication" #-}

-- | 平手の局面
hirate :: Clocks -> Position
hirate = Position Black Board.hirate Stands.empty

-- | 時計以外が同じ場合 True
positionEq :: Position -> Position -> Bool
positionEq a b = at == bt && ab == bb && as == bs
 where
  at = positionTurn a
  bt = positionTurn b
  ab = positionBoard a
  bb = positionBoard b
  as = positionStands a
  bs = positionStands b

-- | 駒の移動
move
  :: SrcSquare
  -> Promotion
  -> DestSquare
  -> Position
  -> Either CloseStatus Position
move src promo dest pos = do
  -- 駒移動
  (newBoard, captured) <- illegalCheck (Board.move src promo dest board)
  let newPos = pos { positionTurn   = Color.turnColor turn
                   , positionBoard  = newBoard
                   , positionStands = Stands.add turn captured stands
                   }
  -- 王手回避チェック
  when (checked turn newPos) (Left (Illegal AbandonCheck))
  pure newPos
 where
  illegalCheck = maybe (Left (Illegal IllegalMove)) pure
  turn         = positionTurn pos
  board        = positionBoard pos
  stands       = positionStands pos

-- | 駒の打ち込み
drop :: PieceType -> DestSquare -> Position -> Either CloseStatus Position
drop pt dest pos = do
  -- 駒の打ち込み
  newStand <- illegalCheck (Stands.drop turn pt stands)
  newBoard <- illegalCheck (Board.drop turn pt dest board)
  let newPos = pos { positionTurn   = Color.turnColor turn
                   , positionBoard  = newBoard
                   , positionStands = newStand
                   }
  -- 王手回避チェック
  when (checked turn newPos)       (Left (Illegal AbandonCheck))
  -- 打ち歩詰めチェック
  when (mate newPos && pt == Pawn) (Left (Illegal DroppedPawnMate))
  pure newPos
 where
  illegalCheck = maybe (Left (Illegal IllegalDrop)) pure
  turn         = positionTurn pos
  board        = positionBoard pos
  stands       = positionStands pos

-- | 時間消費
consumeTime :: Sec -> Position -> Position
consumeTime sec pos = pos { positionClocks = newClocks }
 where
  newClocks = Clocks.consume sec turn clocks
  turn      = positionTurn pos
  clocks    = positionClocks pos

-- | 王手判定
checked :: Color -> Position -> Bool
checked color = Board.checked color . positionBoard

-- | 詰み判定
mate :: Position -> Bool
mate pos = hasKing && nullMovables && nullDroppables
 where
  turn           = positionTurn pos
  hasKing        = not $ Set.null $ Board.kingSquares turn (positionBoard pos)
  nullMovables   = Movables.null $ movables pos
  nullDroppables = Droppables.null $ droppables pos

-- | 駒の移動範囲を取得
movables :: Position -> Movables
movables pos = msf pos ms
 where
  ms    = Board.movables turn board
  turn  = positionTurn pos
  board = positionBoard pos

-- | 駒の移動先から負けになるものを削除
msf :: Position -> Movables -> Movables
msf pos =
  Movables
    . Map.filter (/= Movable.empty)
    . Map.mapWithKey (mf pos)
    . unMovables

-- | 駒の移動先から負けになるものを削除
mf :: Position -> SrcSquare -> Movable -> Movable
mf pos src =
  Movable
    . Map.filterWithKey (\dest _ -> isRight $ move src False dest pos)
    . unMovable

-- | 持ち駒の打ち先範囲を取得
droppables :: Position -> Droppables
droppables pos = dsf pos ds
 where
  ds     = Stands.droppables turn board stands
  turn   = positionTurn pos
  board  = positionBoard pos
  stands = positionStands pos

-- | 駒の打ち先から負けになるものを削除
dsf :: Position -> Droppables -> Droppables
dsf pos =
  Droppables
    . Map.filter (/= Droppable.empty)
    . Map.mapWithKey (df pos)
    . unDroppables

-- | 駒の打ち先から負けになるものを削除
df :: Position -> PieceType -> Droppable -> Droppable
df pos pt =
  Droppable
    . Set.filter (\dest -> isRight $ ShogiX.Shogi.Position.drop pt dest pos)
    . unDroppable
