global.wf ?= {}

i18n = require('i18n')
_ = require('underscore')
moment = require 'moment'

require './init_logger'

require './defaults'

i18n.configure wf.i18n_config


wf.ensure_realms_loaded = (callback) ->
  if wf.all_realms
    callback?()
  else
    wf.info "Reloading realms from db!"
    wf.wow.get_realms (realms) ->
      wf.info "Loaded realms from db, found:#{realms.length}"
      callback?() if realms.length == 0
      wf.all_realms = realms
      regions_to_locales = {}
      for realm in wf.all_realms
#        wf.info "realm:#{realm.name}, region:#{realm.region}, locale:#{realm.locale}"
        region_locales = regions_to_locales[realm.region] ||= []
        locale_found = false
        for locale in region_locales
#          wf.info "checking #{locale} vs #{realm.locale}  = #{locale == realm.locale}"
          if locale == realm.locale
            locale_found = true
            break
        region_locales.push(realm.locale) unless locale_found
      for region,locales of regions_to_locales
        wf.info "Region #{region} has #{locales.length} locales"
        locales.sort()
      wf.regions_to_locales = regions_to_locales
      callback?()


wf.sort_locale = (req) ->
  wf.info "req.locale:#{req?.locale}"
  language_header = req.headers['accept-language']
  browser_locale = "en_US"
  if language_header
    browser_locales = language_header.split(',')[0].split('-')
    browser_locale = "#{browser_locales[0]}_#{browser_locales[1]}"
    wf.info "language header:#{language_header}/#{browser_locale}"
  i18n.setLocale(browser_locale)
  wf.set_locale(req.params.locale, req.params.realm, req.params.region)


locale_valid_for_region = (p_locale, p_region) ->
  return true if p_locale == wf.locale_default 
  return true unless p_region?
  return false unless p_locale?
  return _.contains(wf.regions_to_locales[p_region], p_locale)

wf.set_locale = (p_locale, p_realm, p_region) ->
  p_realm = p_realm?.toLocaleLowerCase()
  p_region = p_region?.toLocaleLowerCase()
  wf.info "user locale:#{i18n.getLocale()}, url locale:#{p_locale}, realm:#{p_realm}/#{p_region} - all realms:#{wf.all_realms?.length}"
  if p_locale? and locale_valid_for_region(p_locale, p_region)
    wf.info "using locale from url:#{p_locale}"
    i18n.setLocale(p_locale)
  else if p_realm?
    for realm in wf.all_realms
      wf.debug "Checking realm #{p_realm}/#{p_region} vs #{realm.name.toLocaleLowerCase()}/#{realm.region}"
      if realm.name.toLocaleLowerCase() == p_realm and realm.region == p_region
        wf.info "Found realm #{p_realm} locale #{realm.locale}"
        i18n.setLocale(realm.locale)
        break
  wf.info "ALL:user derived locale:#{i18n.getLocale()}"
  return i18n.getLocale()


wf.format_date = (dt) ->
  dateMoment = moment(dt).lang(wf.locale_lang[i18n.getLocale()])
  "#{dateMoment.fromNow()}, #{dateMoment.format("D MMM YYYY H:mm")}"

