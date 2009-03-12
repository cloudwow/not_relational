module NotRelational
  module ActsAsNotRelationalApplication
    def self.included(base)
      base.before_filter :prepare_repository
    end
    def prepare_repository
      puts "prepare repo"
      NotRelational::RepositoryFactory.instance.clear_session_cache
    end
  end
end
