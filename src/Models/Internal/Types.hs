{-# LANGUAGE OverloadedStrings #-}

-- | (Try) to be Generic Operation for DB operations
-- 

module Models.Internal.Types where

import           Control.Monad.Trans
import           Database.MongoDB
import           Snap
import           Snap.Snaplet.MongoDB
import qualified Database.MongoDB as DB
import           Data.Bson

import           Models.Internal.Exception

-- | A simple generic MongoDB Persistent class.
-- 
-- 
class MongoDBPersistent a where
  
  -- | Schema name. Implement me like `getSchemaP _ = u "abc"`
  --
  mongoColl :: a -> Collection
  
  -- | Transform Data to MongoDB document type
  --
  toMongoDoc :: a -> Document
  
  -- | Transform MongoDB document to perticular type
  --
  fromMongoDoc :: Document -> IO a
  
  -- | Get ObejectId
  -- 
  mongoGetId :: a -> Maybe ObjectId
  
  -- | Update ID field of model after insert to mongoDB successfully.
  -- 
  mongoInsertId :: a      -- ^ original data that about to be save.
                -> Value  -- ^ return value after mongoDB.insert, should be a ObjectID.
                -> a      -- ^ updated data with ID filed get updated.
  

-- | FIXME: Insert ID after save successfully. @see Topic.hs: 51
-- | Simple MongoDB Save Operation 
-- 
mongoInsert :: (MonadIO m, MonadState app m, HasMongoDB app, MongoDBPersistent a) 
         => a    -- ^ new model that will be save
         -> m a  -- ^ saved model with id.
mongoInsert x = eitherWithDB (DB.insert (mongoColl x) (toMongoDoc x))
                >>= either failureToUE (return . mongoInsertId x)


-- | Fetch All items in the collection
-- 
-- WHY IT FAILED: let selection = select [] (getSchemaP (undefined::a))
-- 
mongoFindAll :: (MonadIO m, MonadState app m, HasMongoDB app, MongoDBPersistent a)
                => a       -- ^ an empty model. (work around for the concern below.
                -> m [a]   -- ^ list of model data that has been retrieved.
mongoFindAll x  = 
  eitherWithDB (rest =<< find (select [] (mongoColl x)))
  >>= liftIO . mapM fromMongoDoc . either (const []) id


-- | Find One item.
--
mongoFindOne :: (MonadIO m, MonadState app m, HasMongoDB app, MongoDBPersistent a)
                => a
                -> m a
mongoFindOne x =
  eitherWithDB (fetch (select ("_id" =? mongoGetId x) (mongoColl x)))
  >>= either failureToUE (liftIO . fromMongoDoc)


-- | Find some via list of IDs.
--
mongoFindIds :: (MonadIO m, MonadState app m, HasMongoDB app, MongoDBPersistent a)
                 => a
                 -> [ObjectId] 
                 -> m [a]
mongoFindIds = mongoFindSomeBy "_id"
    

-- | Find some via list of certain column name.
--   MAYBE: this turns out to be complicated.
--
mongoFindSomeBy :: (MonadIO m, MonadState app m, HasMongoDB app, MongoDBPersistent a, Val b)
                 => Label     -- ^ Column name
                 -> a
                 -> [b]       -- ^ List of values
                 -> m [a]
mongoFindSomeBy _ _ [] = return []
mongoFindSomeBy l x xs = do
    let collect = mongoColl x
        selIn = selectIn xs
        sel = select [ l =: selIn ] collect
    eitherWithDB $ rest =<< find sel
    >>= liftIO . mapM fromMongoDoc . either (const []) id


-- | Prepare "$in" statement for query.
--
selectIn :: Val a => [a] -> Document
selectIn xs = ["$in" =: xs]
