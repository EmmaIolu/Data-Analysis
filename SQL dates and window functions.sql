with combined_data as (
      select
      ad_date,
      campaign_name,
      adset_name,
      coalesce(spend, 0) as spend,
      coalesce(impressions,0) as impressions,
      coalesce(reach,0) as reach,
      coalesce(clicks,0) as clicks,
      coalesce(leads, 0) as leads,
      coalesce(value,0) as value,
      url_parameters
      from
      facebook_ads_basic_daily fabd
      join
      facebook_campaign fc on fabd.campaign_id =fc.campaign_id
      join
      facebook_adset fa on fabd.adset_id =fa.adset_id
      union all
      select
      ad_date,
      campaign_name,
      adset_name,
      coalesce(spend, 0) as spend,
      coalesce(impressions, 0) as impressions,
      coalesce(reach, 0) as reach ,
      coalesce(clicks,0) as clicks,
      coalesce(leads,0) as leads,
      coalesce(value,0) as value,
      url_parameters
      from
      google_ads_basic_daily gabd),
      --calculul metricilor lunar
      monthly_stats as (
      select date_trunc('month',ad_date) as ad_month,
      campaign_name,
      sum(spend) as total_cost,
      sum(impressions) as total_impressions,
      sum(clicks) as total_clicks,
      sum(value) as total_value,
      case when sum(clicks) >0 then sum(spend)::numeric / sum(clicks)::numeric
      end as CPC,
      case when sum(impressions)>0 then sum(spend)::numeric/sum(impressions)::numeric * 1000
      end as CPM,
      case when sum(impressions)>0 then sum(clicks)::numeric/sum(impressions)::numeric * 100
      end as CTR,
      case when sum(spend)>0 then(sum(value)::numeric - sum(spend)::numeric)/sum(spend)::numeric*100
      end as ROMI,
      case
      when lower(substring(url_parameters, 'utm_campaign=([^\&]+)'))='nan' then null
      else lower(substring(url_parameters, 'utm_campaign=([^\&]+)'))
      end as utm_campaign
 	  from combined_data
 	  group by ad_date, campaign_name, url_parameters
 	  ),
 	   --calculul indicatorilor pe luna anterioara
 	  monthly_stats_changes as (
      select *,
      lag(CPC) over (partition by utm_campaign order by ad_month desc) as previos_month_CPC,
      lag(CPM) over (partition by utm_campaign order by ad_month desc) as previos_month_CPM,
      lag(CTR) over (partition by utm_campaign order by ad_month desc) as previos_month_CTR,
      lag(ROMI) over (partition by utm_campaign order by ad_month desc) as previos_month_ROMI
      from monthly_stats)	
      --calculul diferentelor versus luna anterioara
 		select*,
		case when previos_month_CPC > 0 then CPC::numeric/previos_month_CPC
 		when previos_month_CPC=0 then 1
 	    end as CPC_change,
		case when previos_month_CPM > 0 then CPC::numeric/previos_month_CPM
 		when previos_month_CPM=0 then 1
 	    end as CPM_change,
		case when previos_month_CTR > 0 then CTR::numeric/previos_month_CTR
 		when previos_month_CTR=0 then 1
 	    end as CTR_change,
		case when previos_month_ROMI > 0 then ROMI::numeric/previos_month_ROMI
 		when previos_month_ROMI=0 then 1
 	    end as ROMI_change
 	    from monthly_stats_changes