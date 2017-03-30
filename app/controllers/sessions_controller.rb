# frozen_string_literal: true

class SessionsController < ApplicationController
  include RedisStore

  before_action :authenticate_user!, only: [:destroy]

  def create
    @user = User.find_by(mobile: session_params[:mobile])
    if @user && @user.authenticate(session_params[:password])
      @token = gen_random_token
      save_token_to_redis(@token, @user.id)
    else
      render json: { error: 'Invalid mobile/password combination' }, status: :unauthorized
    end
  end

  def destroy; end

  private

  def gen_random_token
    token = Digest::SHA1.hexdigest([Time.now, rand].join)
    loop do
      return token unless RedisStore.hexists(token, 'user_id')
      token = Digest::SHA1.hexdigest([Time.now, rand].join)
    end
    token
  end

  def save_token_to_redis(token, user_id)
    RedisStore.hmset(token, 'user_id', user_id)
    RedisStore.expire(token, 604_800) # 1 week minute expiration (but you can set this to whatever - shorter is more secure)
  end

  def session_params
    params.require(:session).permit(:mobile, :password)
  end
end
