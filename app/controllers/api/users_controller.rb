class Api::UsersController < ApplicationController
  def index
    users = User.active.order(:first_name, :last_name)

    render json: users.map { |user|
      {
        id: user.id,
        firstName: user.first_name,
        lastName: user.last_name,
        email: user.email,
        fullName: user.full_name
      }
    }
  end

  def show
    user = User.find(params[:id])

    render json: {
      id: user.id,
      firstName: user.first_name,
      lastName: user.last_name,
      email: user.email,
      fullName: user.full_name
    }
  end
end
