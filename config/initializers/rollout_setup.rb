require 'fakeredis' if Rails.env.test?
require 'rollout_ui/engine'

# namespace keys; for example, development:feature:beta
namespace = Redis::Namespace.new(Rails.env, redis: Redis.new)

# TODO global recommended by gem author, consider a singleton proxy
$rollout = Rollout.new(namespace)
RolloutUi.wrap($rollout)

$rollout.define_group(:admin) {|user| user.admin? }

# $rollout.activate_group(:beta, :admin)

# $rollout.activate_user(:feature, user)
# $rollout.active?(:feature, user)

# $rollout.activate_percentage(:feature, 10) # for user

