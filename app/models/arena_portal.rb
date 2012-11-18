# -*- encoding : utf-8 -*-
class ArenaPortal
  def id
    -3
  end

  def default_gmtv_channel_id
    1
  end

  def small_header
    nil
  end

  def channels
    GmtvChannel.find(
        :all,
        :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)",
        :order => 'gmtv_channels.id ASC',
        :include => :user)
  end

  def name
    'Gamersmafia Arena'
  end

  def layout
    'default'
  end

  def code
    'arena'
  end

  def home
    'arena'
  end

  def skin_id
    nil
  end

  def skins(user)
    # TODO HACK HACK HACK
    [Skin.find_by_hid('arena')] + Skin.find(:all)
  end

  def skin
    Skin.find_by_hid('default')
  end

  def respond_to?(method_id, include_priv = false)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      true
    elsif /_categories/ =~ method_id.to_s then
      # it must have at least one
      true
    else
      super
    end
  end

  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        ArenaPortalPollProxy
      else
        cls_name = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s))
        cls = Object.const_get(cls_name)
        if Cms::CLANS_CONTENTS.include?(cls_name)  # es una clase cuya tabla tiene clan_id, añadimos constraint
          GenericContentProxy.new(cls, 'arena')
        else
          cls
        end
      end
    elsif /_categories/ =~ method_id.to_s then
      Term.single_toplevel(:arena)
    else
      super
    end
  end

  def terms_ids(taxonomy)
    arena_portal = Term.with_taxonomy("Homepage").find_by_slug!('arena')
    arena_portal.all_children_ids(:taxonomy => taxonomy)
  end

  def competitions
    Competition
  end

  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    Term.toplevel(:slug => 'arena')
  end
end

class ArenaPortalPollProxy
  def self.current
    Term.single_toplevel(:slug => 'arena').poll.published.find(:all, :conditions => "starts_on <= now() and ends_on >= now()", :order => 'created_on DESC', :limit => 1)
  end

  def self.method_missing(method_id, *args)
    GenericContentProxy.new(Poll).send(method_id, *args)
  end

  def self.respond_to?(method_id)
    GenericContentProxy.new(Poll).respond_to?(method_id)
  end
end
