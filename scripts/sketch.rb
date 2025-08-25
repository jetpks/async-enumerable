# i'm flailing a little bit here. what am i going for?

class Foo
  include Async::Enumerable
  def_async_enumerable :@bar, max_fibers: 100, pipeline: true

  def initialize
    @bar = []
  end

  def perform
    Sync do |parent|
      # @bar = [1, 2, 3, 4]
      async(parent:) # update the instance config to use this parent
        .map { |x| x + 1 } # async map over @bar, returning a task that adds 1 for each
        # => Task{1 + 1}, Task{2 + 1}, Task{3 + 1}, Task{4 + 1} # unordered, individual
        .accumulate(2, timeout_ms: 200) # gather batches up to 2 waiting up to 200ms before sending
        # => [Task{1 + 1}, Task{2 + 1}], [Task{3 + 1}, Task{4 + 1}] # unordered
        .map { |x| x.wait.sum }
        # x is an accumulated Async::Enumerator<Task>
        # wait blocks until all included tasks are resolved, then returns self
        # sum is an Enumerable method called on the Async::Enumerator
        # => [???]
        .flatten
        # => [Task...]
        .sync # resolve the entire pipeline and all tasks in it
        # => [2, 3, 4, 5]
    end
  end
end
