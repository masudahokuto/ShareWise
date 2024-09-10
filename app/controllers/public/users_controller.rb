class Public::UsersController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]  # ユーザーがログインしていることを確認

  def mypage
    @user = current_user
    @posts = @user.posts.page(params[:page]).per(10)
  end

  def index
    @current_user = current_user
    if @current_user
      @users = User.includes(:posts).where(is_active: true).where.not(id: @current_user.id).page(params[:page]).per(10)
    else
      @users = User.includes(:posts).where(is_active: true).page(params[:page]).per(10) # ログインしていない場合もアクティブなユーザーのみを表示
    end
  end

  def show
    @user = User.find(params[:id])
    if @user.is_active == false
      redirect_to users_path
    else
      @posts = @user.posts.page(params[:page]).per(10)
    end
    # 自分のプロフィールページへの直接アクセスをマイページにリダイレクト
    if @user == current_user
      redirect_to mypage_users_path and return
    end
    # フォロー判定
    @is_following = current_user.following?(@user) if current_user.present?
    @relationship = current_user.relationships.find_by(followed_id: @user.id) if user_signed_in?
    # フォローフォロワー数確認
    @followings_count = @user.followings.count
    @followers_count = @user.followers.count
  end

  def likes
    @user = User.find(params[:id])
    if current_user.nil? || current_user != @user
      redirect_to posts_path
      return
    end
    @posts = @user.liked_posts.page(params[:page]).per(10)
  end

  def edit
    @user = User.find(params[:id])
    # ユーザーが自分のプロフィールを編集できるかを確認する
    if @user != current_user
      redirect_to users_path # 適切なリダイレクト先に変更可能
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to mypage_users_path, notice: 'プロフィールが更新されました'
    else
      render :edit
    end
  end

  def withdraw
    @user = current_user
    if @user.update(is_active: false)
      sign_out_and_redirect @user
      flash[:notice] = '退会処理が完了しました'
    else
      redirect_to mypage_path, alert: '退会処理に失敗しました'
    end
  end

  private

  def user_params
    params.require(:user).permit(:last_name, :first_name, :nick_name, :profile, :gender, :birthday_1i, :birthday_2i, :birthday_3i, :email, :profile_image, :is_active)
  end
end
