class ContributionsController < ApplicationController
  before_filter :only_admins
  before_filter :ensure_api_connection

  def index
    Donortools::Persona.setup_connection
    if params[:person_id]
      @person = Person.find(params[:person_id])
      @donor = @person.donor
      render :action => 'person_index'
    else
      @count_unsynced = Person.unsynced_to_donortools.count
    end
  end

  def sync
    if params[:person_id]
      if request.post?
        @person = Person.find(params[:person_id])
        @person.update_donor
        flash[:notice] = t('contributions.record_synced')
        redirect_to person_contributions_path(@person)
      end
    else
      if request.get?
        @unsynced_people = Person.unsynced_to_donortools(:all, :include => :family, :order => 'last_name, first_name').paginate(:page => params[:page], :per_page => 500)
      elsif request.post?
        if params[:all_ids] == 'true'
          @ids = Person.unsynced_to_donortools(:select => 'id').map { |p| p.id }
        else
          @ids = Array(params[:ids])
        end
        Person.all(:conditions => ["id in (?)", @ids.shift(Donortools::Persona::SYNC_AT_A_TIME)]).each do |person|
          person.update_donor
        end
        respond_to do |format|
          format.js
        end
      end
    end
  end

  private

    def only_admins
      unless @logged_in.admin?(:manage_contributions)
        render :text => t('only_admins'), :layout => true, :status => 401
        return false
      end
    end

    def ensure_api_connection
      unless Donortools::Persona.can_sync?
        render :text => t('contributions.api_not_configured_html', :url => administration_settings_path(:anchor => 'Services')), :layout => true
        return false
      end
    end

end
