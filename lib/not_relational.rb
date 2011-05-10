# not_relational is a really cool new thing.  This is the gem you are looking
# for.
# Author::    David Knight  (mailto:david@cloudwow.com)
# Copyright:: Copyright (c) 2009 David Knight
# License::   Distributes under the same terms as Ruby


require "#{File.dirname(__FILE__)}/not_relational/errors.rb"
require "#{File.dirname(__FILE__)}/not_relational/repository_base.rb"
require "#{File.dirname(__FILE__)}/not_relational/sdb_repository.rb"
require "#{File.dirname(__FILE__)}/not_relational/repository_factory.rb"
require "#{File.dirname(__FILE__)}/not_relational/acts_as_not_relational_application.rb"
require "#{File.dirname(__FILE__)}/not_relational/memory_repository.rb"
require "#{File.dirname(__FILE__)}/not_relational/location.rb"
require "#{File.dirname(__FILE__)}/not_relational/geo.rb"
require "#{File.dirname(__FILE__)}/not_relational/domain_model.rb"
require "#{File.dirname(__FILE__)}/not_relational/storage.rb"
require "#{File.dirname(__FILE__)}/not_relational/s3.rb"
require "#{File.dirname(__FILE__)}/not_relational/attribute_range.rb"
require "#{File.dirname(__FILE__)}/not_relational/or_condition.rb"
require "#{File.dirname(__FILE__)}/not_relational/starts_with_condition.rb"
require "#{File.dirname(__FILE__)}/not_relational/is_null_transform.rb"
require "#{File.dirname(__FILE__)}/not_relational/geo.rb"
require "#{File.dirname(__FILE__)}/not_relational/repository.rb"
require "#{File.dirname(__FILE__)}/not_relational/tag_cloud.rb"
