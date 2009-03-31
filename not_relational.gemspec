# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{not_relational}
  s.version = "0.1.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["cloudwow"]
  s.date = %q{2009-03-31}
  s.email = %q{david@cloudwow.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "VERSION.yml", "lib/not_relational", "lib/not_relational/acts_as_not_relational_application.rb", "lib/not_relational/and_condition.rb", "lib/not_relational/attribute_range.rb", "lib/not_relational/berkeley_repository.rb", "lib/not_relational/configuration.rb", "lib/not_relational/crypto.rb", "lib/not_relational/domain_model.rb", "lib/not_relational/domain_model_cache_item.rb", "lib/not_relational/equals_condition.rb", "lib/not_relational/geo.rb", "lib/not_relational/index_description.rb", "lib/not_relational/is_null_transform.rb", "lib/not_relational/lazy_loading_text.rb", "lib/not_relational/local_storage.rb", "lib/not_relational/memcache_repository.rb", "lib/not_relational/memory_repository.rb", "lib/not_relational/memory_storage.rb", "lib/not_relational/or_condition.rb", "lib/not_relational/property_bag.rb", "lib/not_relational/property_description.rb", "lib/not_relational/query_string_auth_generator.rb", "lib/not_relational/reference.rb", "lib/not_relational/repository_factory.rb", "lib/not_relational/repository_interface.rb", "lib/not_relational/s3.rb", "lib/not_relational/sdb_formatter.rb", "lib/not_relational/sdb_monkey_patch.rb", "lib/not_relational/sdb_repository.rb", "lib/not_relational/starts_with_condition.rb", "lib/not_relational/storage.rb", "lib/not_relational/tag_cloud.rb", "lib/not_relational/tracker_description.rb", "lib/not_relational/uuid.rb", "lib/not_relational.rb", "test/models", "test/models/album.rb", "test/models/blurb.rb", "test/models/blurb_wording.rb", "test/models/comment.rb", "test/models/error.rb", "test/models/friend.rb", "test/models/friend_request.rb", "test/models/geo.rb", "test/models/group.rb", "test/models/language.rb", "test/models/media_file.rb", "test/models/media_item.rb", "test/models/message.rb", "test/models/node.rb", "test/models/outgoing_email.rb", "test/models/page_view_detail.rb", "test/models/page_view_summary.rb", "test/models/place.rb", "test/models/rating.rb", "test/models/tag.rb", "test/models/user.rb", "test/models/user_event.rb", "test/models/weblab.rb", "test/unit_tests", "test/unit_tests/album_test.rb", "test/unit_tests/bdb_test.rb", "test/unit_tests/blurb_test.rb", "test/unit_tests/collection_test.rb", "test/unit_tests/comment_test.rb", "test/unit_tests/composite_key_test.rb", "test/unit_tests/enum_test.rb", "test/unit_tests/group_test.rb", "test/unit_tests/mediaitem_test.rb", "test/unit_tests/memcache_repository_test.rb", "test/unit_tests/memory_repository_test.rb", "test/unit_tests/node_test.rb", "test/unit_tests/place_test.rb", "test/unit_tests/reference_set_test.rb", "test/unit_tests/repository_factory_test.rb", "test/unit_tests/tag_test.rb", "test/unit_tests/user_test.rb", "test/unit_tests/uuid.state", "test/utils", "test/utils/create_sdb_domains.rb", "test/utils/whack_domains.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/cloudwow/not_relational}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
