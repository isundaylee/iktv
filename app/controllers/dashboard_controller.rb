require 'playlist'

class DashboardController < ApplicationController
  def dashboard
    @term = params[:term]


    if @term.present?
      byname = Song.where('name like ?', "%#{@term.strip}%").limit(100).to_a
      byartist = Song.where(artist: @term).limit(100).to_a
      @songs = byname + byartist
    else
      @songs = []
    end
  end

  def player
  end
end
