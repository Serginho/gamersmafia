# -*- encoding : utf-8 -*-
class TagsController < ApplicationController
  def index

  end

  def show
    @tag = Term.find_by_slug!(params[:id])
    @title = @tag.name
  end
end
