# To change this template, choose Tools | Templates
# and open the template in the editor.


require 'test/unit'
require 'bdb'
class BdbTest < Test::Unit::TestCase

  def test_foo


  env = Bdb::Env.new(0)
  env_flags =  Bdb::DB_CREATE |    # Create the environment if it does not already exist.
               Bdb::DB_INIT_TXN  | # Initialize transactions
               Bdb::DB_INIT_LOCK | # Initialize locking.
               Bdb::DB_INIT_LOG  | # Initialize logging
               Bdb::DB_INIT_MPOOL  # Initialize the in-memory cache.
  env.open('/tmp', env_flags, 0);

  db = env.db
  db.open(nil, 'db1.db', nil, Bdb::Db::BTREE, Bdb::DB_CREATE | Bdb::DB_AUTO_COMMIT, 0)

  txn = env.txn_begin(nil, 0)
  db.put(txn, 'key', 'value123', 0)
  txn.commit(0)

  value = db.get(nil, 'key', nil, 0)

      assert_equal('value123',value)
  db.close(0)
  env.close

 end
end
