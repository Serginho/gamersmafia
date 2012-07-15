# -*- encoding : utf-8 -*-
class CacheController < ApplicationController
  def thumbnails
    # TODO proteger
    raise ActiveRecord::RecordNotFound if (not %w(f k i).include?(params[:mode]) or not params[:dim])
    sp = request.fullpath

    begin
      5.times { sp = sp[(sp.index('/') + 1)..-1] }
    rescue
      raise ActiveRecord::RecordNotFound
    end
    sp = URI::unescape(sp.gsub(/\.\./, '').gsub('+', '%20'))
    raise ActiveRecord::RecordNotFound if not sp =~ /\./ or sp.match(/\/$/) # no es una url válida

    match_dim = params[:dim].match(/([1-9]{1}[0-9]{0,4})x([1-9]{1}[0-9]{0,4})/)
    raise ActiveRecord::RecordNotFound if not match_dim

    thumbpath = "#{Rails.root}/public/cache/thumbnails/#{params[:mode]}/#{match_dim[1]}x#{match_dim[2]}/#{sp}"
    Cms::image_thumbnail("#{Rails.root}/public/#{sp}", thumbpath, match_dim[1].to_i, match_dim[2].to_i, params[:mode])

    send_file(thumbpath, :type => 'image/jpg', :stream => false, :disposition => 'inline')
  end

  def faction_users_ratios
    require 'rubygems'
    require 'gruff'
    g = Gruff::Mini::Pie.new(150)
    g.theme = {
      :marker_color => '#666666',
      :background_colors => %w(white white)
    }

    if params[:faction_id].kind_of?(Array)
      params[:faction_id] = params[:faction_id][0]
    end
    f = Faction.find(params[:faction_id].gsub(".png", "").to_i)
    g.data('Activos', [f.active_members_count], '#BB0012')
    g.data('Inactivos', [f.inactive_members_count], '#BBA9AB')
    g.font= "#{Rails.root}/public/ttf/verdana.ttf"
    # no usamos date para evitar ataques de denegación de servicio generando imágenes para cada año
    dst = "#{Rails.root}/public/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/#{f.id}.png"
    FileUtils.mkdir_p(File.dirname(dst)) if !File.exists?(File.dirname(dst))
    begin
      g.write(dst)
    rescue NoMethodError # necesario para que Gruff no genere error 500 al intentar pintar gráficas de facciones con 0 miembros
      raise ActiveRecord::RecordNotFound
    end

    raise 'foo' unless File.exists? dst

    if request.respond_to?(:user_agent) and /MSIE/ =~ request.user_agent
      send_file(dst, :type => 'image/png', :streaming => true, :disposition => 'inline')
    else
      redirect_to request.path
    end
  end
end
