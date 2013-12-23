require "usecasing/version"

module UseCase
  autoload :Context,       'usecasing/context'
  autoload :Base,          'usecasing/base'
  autoload :CyclicFinder,  'usecasing/cyclic_finder'
end
