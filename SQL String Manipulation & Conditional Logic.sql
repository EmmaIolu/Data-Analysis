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
      google_ads_basic_daily gabd )
      
      
select
      ad_date,
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
 where clicks > 0 and impressions > 0 and spend > 0
 group by 1,2,11;
 

