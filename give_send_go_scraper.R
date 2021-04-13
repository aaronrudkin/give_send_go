library(tidyverse)
library(glue)
library(rvest)
library(jsonlite)
library(lubridate)

# From single category -> unhydrated campaign
get_campaign_list = function(category_name) {
  page = 1
  existing_data = NULL
  done = FALSE
  
  while(!done) {
    print(glue("Reading page {page} of category {category_name}"))
    data = 
      read_html(
        glue("https://givesendgo.com/searchbycat?category={category_name}&page={page}&per-page=9") %>% URLencode()
      ) %>%
      html_nodes("div.main_camps") %>%
      map_dfr(function(node) {
        campaign_title = node %>% html_node("div.camp_title") %>% html_text()
        author = node %>% html_node("div.fund_by") %>% html_text() %>%
          str_trim() %>% str_replace("by ", "") %>% str_trim()
        short_url = node %>% html_node("a") %>% html_attr("href")
        raised = node %>% html_node("div.price-range-trade") %>%
          html_node("span") %>% html_text() %>% str_trim()
        
        tibble(
          campaign_title = campaign_title,
          author = author,
          short_url = short_url,
          raised = raised
        )
      })
    
    if(is.null(existing_data)) { existing_data = data }
    else {
      # Duplicate page
      if(any(data$short_url %in% existing_data$short_url)) {
        break
      }
      
      existing_data = bind_rows(existing_data, data)
      
      if(nrow(data) != 9) {
        break
      }
    }
    
    page = page + 1
  }
  
  if(!is.null(existing_data)) {
    existing_data = existing_data %>% mutate(category_name = category_name)
  }
  
  existing_data
}

# From single unhydrated campaign -> single hydrated campaign
get_campaign_id = function(row) {
  short_url = row %>% pull(short_url)
  print(glue("Getting campaign ID for campaign {short_url}"))
  
  safe_campaign_id = possibly(function(x) {
    everything = read_html(x) 
    
    list(
      "campaign_id" = everything %>%
        html_node("form#pray-now-form") %>%
        html_node("input") %>%
        html_attr("value") %>%
        as.numeric(),
      "campaign_pitch" = everything %>%
        html_node("span#fund_story_html") %>%
        html_text() %>%
        str_trim()
    )
  }, 
  otherwise = list("campaign_id" = NA_real_, "campaign_pitch" = NA_character_), 
  quiet = TRUE)
  
  row %>% mutate(
    !!!safe_campaign_id(glue("https://givesendgo.com{short_url}"))
  )
}

# From hydrated campaign id -> donation data frame
get_campaign_donations = function(campaign_id) {
  url = glue("https://givesendgo.com/donation/recentdonations?camp={campaign_id}&donation=null")
  data = fromJSON(url)
  done = FALSE
  all_donations = NULL
  num_pages = 1
  print(glue("Reading donations from campaign ID {campaign_id}..."))
    
  while(!done) {
    donations = data$returnData$donations
    if(!length(donations) || !nrow(donations)) {
      break
    }
    
    if(is.null(all_donations)) { all_donations = donations }
    else { all_donations = bind_rows(all_donations, donations) }
    
    min_donation = donations %>% pull(donation_id) %>% min()
    
    next_page = glue("https://givesendgo.com/donation/recentdonations?camp={campaign_id}&donation={min_donation}")
    data = fromJSON(next_page)
    num_pages = num_pages + 1
    print(glue("  Reading page {num_pages}..."))
  }
  
  all_donations %>%
    mutate(fix_date = fix_relative_dates(donation_date)) %>%
    select(1:donation_anonymous, fix_date, lovecount:likescount) %>%
    rename(donation_date = fix_date)
}

# From category list -> unhydrated campaigns data frame
get_all_campaigns = function() {
  category_list = c(
    "Adoption", "Animal/Pets", "Business", "Church", "Community", 
    "Competitive", "Creative", "Current Events", "Education", "Emergency", 
    "Evangelism", "Event", "Family", "Legal", "Medical", "Memorial", 
    "Mission", "Non-Profit")
  
  all_campaigns = category_list %>% map_dfr(get_campaign_list)
  
  all_campaigns %>% group_by(short_url) %>%
    mutate(cn2 = paste0(sort(category_name), collapse = ", ")) %>%
    select(-category_name) %>%
    rename(category_name = cn2) %>%
    unique()
  
  all_campaigns
}

# From unhydrated campaign data frame -> hydrated campaign data frame
hydrate_all_campaigns = function(all_campaigns) {
  1:nrow(all_campaigns) %>% map_dfr(function(row_number) {
    row = all_campaigns[row_number, ]
    get_campaign_id(row)
  })
}

# From hydrated campaign data frame -> donations data frame
get_all_donations = function(all_campaigns) {
  wrap_safely = possibly(
    get_campaign_donations,
    otherwise = NULL, quiet = TRUE)
  
  all_campaigns %>% pull(campaign_id) %>%
    na.omit() %>%
    map_dfr(wrap_safely)
}

# Fix relative dates -- this is not 100% accurate, if I scrape at 1AM, then 
# 2 hours ago = yesterday. But it's close enough, and of course this only
# impacts donations < 1 day old.
fix_relative_dates = function(date) {
  case_when(
    str_detect(date, "mins") ~ today(),
    str_detect(date, "hrs") ~ today(),
    str_detect(date, "days") ~ today() - as.numeric(str_extract(date, "[0-9]*"))
  )
}

# Let's do this!
all_campaigns = get_all_campaigns()
all_campaigns = hydrate_all_campaigns(all_campaigns)
all_donations = get_all_donations(all_campaigns)

write_csv(all_campaigns, "give_send_go_campaigns.csv")
write_csv(all_donations, "give_send_go_donations.csv")

anonymous_donations = all_donations %>%
  mutate(donation_name = case_when(
    donation_anonymous == 1 ~ "data omitted",
    TRUE ~ donation_name
  ))

write_csv(anonymous_donations, "give_send_go_donations_anonymous.csv")
