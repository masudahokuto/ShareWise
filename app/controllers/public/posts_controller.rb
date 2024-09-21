class Public::PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :correct_user, only: [:edit, :update]
  before_action :redirect_if_admin, only: [:index, :show]
  def new
    @user = current_user
    @post = Post.new
  end

  def create
    @post = current_user.posts.new(post_params) # current_user を使用して投稿を作成
    if @post.save
      flash[:success] = "投稿しました"
      redirect_to mypage_users_path
    else
      flash[:alert] = "エラーが発生しました"
      redirect_back(fallback_location: root_path)
    end
  end

  def index
    @current_user = current_user
    @posts = Post.active_user_posts.order(created_at: :desc).page(params[:page]).per(10)

    if params[:query].present?
      @posts = @posts.search(params[:query])
    end
  end

def show
  @post = Post.find_by(id: params[:id])

  if @post.nil? || !@post.user.is_active
    redirect_back(fallback_location: root_path)
  elsif current_user.nil? && @post.user.is_active
    redirect_back(fallback_location: root_path)
  else
    @current_user = current_user
    @user = @post.user
    @post_comments = @post.post_comments.active_user_comments.page(params[:page]).per(10)
    @post_comment = PostComment.new
  end
end

  def search
    @current_user = current_user
    @posts = Post.active_user_posts.search_by_body(params[:query]).order(created_at: :desc).page(params[:page]).per(10)
  end

  def edit
    @user = current_user
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_back(fallback_location: root_path)
  end

  # contentのpost機能
  def create_from_content
    content = Content.find(params[:id])
    # Postモデルのbodyにcontent_nameとbodyとuser_idをセット
    @post = Post.new(
      body: "#{content.content_name}\n\n#{content.body}",
      user_id: current_user.id
    )

    # ContentのimagesをPostのimagesにコピー
    if content.images.attached?
      content.images.each do |image|
        @post.images.attach(image.blob)
      end
    end

    if @post.save
      flash[:success] = "投稿しました"
      redirect_to post_path(@post)
    else
      flash[:alert] = "エラーが発生しました"
      redirect_to root_path
    end
  end

  private

  # 自分以外のuserがedit、update、destroy出来ないようにする
  def correct_user
    @post = Post.find(params[:id])
    unless @post.user == current_user
      redirect_to posts_path
    end
  end

  def post_params
    params.require(:post).permit(:body, :user_id, images: [])
  end

  def redirect_if_admin
    if admin_signed_in?
      redirect_to admin_path, alert: "管理者はこのページにアクセスできません。"
    end
  end
end
