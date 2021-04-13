# give_send_go

This is a scraper to scrape all campaigns and donations from the crowdfunding website GiveSendGo

### Inventory

* `give_send_go_scraper.R` - The scraper, written in R using rvest. The code is relatively self-documenting. 
* `give_send_go_campaigns.csv` - A list of all campaigns on givesendgo.com
* `give_send_go_donations_anonymous.csv` - A list of all donations to campaigns on givesendgo.com, with names redacted for anonymous donations.
* `give_send_go.Rproj` - The R project file.

### `give_send_go_campaigns.csv`

The contents of this file are organized as follows:

| campaign_title | author | short_url | raised | category_name | campaign_id | campaign_pitch |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| BIG TECH HAS NOW OFFICIALLY CANCELED ME | Josh Bernstein | /GVZ5 | $ 7529 Raised of $ 5000 | Current Events | 28644 | *omitted here* |
| Support former LMPD Detective Brett Hankison | Joe Langley | /GWCZ | $ 4010 Raised of $ 75000 | Current Events | 29055 | *omitted here* |
| Patriot Fund for Jorge Riley | Dacian American | /JorgeRiley | $ 383 Raised of $ 33000 | Current Events | 33012 | *omitted here* |
| Help Fund NewMedia To Fight Back | William Mitchell | /NewMedia | $ 3476 Raised of $ 10000 | Current Events | 31273 | *omitted here* |
| Chris Zimmerman and the 1st Amendment | Jennifer Zimmerman | /chriszimmerman | $ 7037 Raised of $ 30000 | Current Events | 32446 | *omitted here* |
| Justice League of America Vote Fraud Investigation | Jim Hoft | /GX7W | $ 141190 Raised of $ 150000 | Current Events | 29916 | *omitted here* |

The columns are as follows:

* *campaign_title*: The display title of the campaign
* *author*: The person or organization that created the campaign
* *short_url*: The "vanity url" used to access the website, e.g. [https://givesendgo.com/GX7W](https://givesendgo.com/GX7W)
* *raised*: The current donation amount and the donation target
* *category_name*: Which category the campaign was submitted to on the site. Some campaigns are submitted to multiple categories, in which case this will be comma separated text.
* *campaign_id*: An internal numeric ID used to represent the campaign -- this is how you can match the campaigns to donations
* *campaign_pitch*: Full text of the campaign operator's pitch (e.g. what they are requesting money for).

### `give_send_go_donations_anonymous.csv`

The contents are organized as follows:

| donation_id | campaign_id | donation_amount | donation_comment | donation_conversion_rate | donation_name | donation_anonymous | donation_date | lovecount | likescount |
| ------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | 
| 43909 | 19915 | 20.00 | Thank you Lord for providing every dollar and then some! Blessings. | 1.000000 | Lisa Couture | 0 | 2019-06-05 | 0 | 0 |
| 43908 | 19915 | 50.00 | Praying God will bless Alex so he can buy his hot dog cart! | 1.000000 | data omitted | 1 | 2019-06-05 | 0 | 0 |
| 43750 | 19231 | 20.00 | God speed sweet sister in Christ. | 1.000000 | Jennifer M Decker | 0 | 2019-06-03 | 0 | 0 |
| 42424 | 19231 | 100.00 | | 1.000000 | *data omitted* | 1 | 2019-05-13 | 0 | 0 |

The columns:

* *donation_id*: An internal donation ID, these exist across campaigns not just within campaigns
* *campaign_id*: Which campaign the donation was for
* *donation_amount*: The amount of the donation
* *donation_comment*: A text comment for the donation if one was left
* *donation_conversion_rate*: I believe this is an exchange rate for non-USD donations, though there are few in the database.
* *donation_name*: The name of the donor. I have removed names for any donor whose donation was anonymous.
* *donation_anonymous*: Whether the donation is anonymous. Crucially, the name of the donor is still visible in the original data if the donation is anonymous, so the donation is not anonymous.
* *donation_date*: A relative timestamp for the donation -- donations on 2021-04-12 may actually come from 2021-04-11; this is because the reported dates are imprecise and relative to the date at time of scraping and I did not bother to correct relative dates from less than one day ago.
* *lovecount*: This appears to be a social media reaction function
* *likescount*: This appears to be a social media reaction function

I went back and forth on whether or not to manually censor names of anonymous donors in the dataset available and ultimately decided to, but of course as I mention above, the data is not censored on the website when scraped, so nothing is actually anonymous on this website.

### Support and use

I wrote this scraper after reading coverage of GiveSendGo in [The Guardian](https://www.theguardian.com/world/2021/apr/10/proud-boys-far-right-givesendgo-christian-fundraising-site). The article suggested that a "transparency group" had bulk downloaded data from the website and made it available to select journalists. Because the data are not publicly available, I conducted my own scrape. I view this data to be of public interest. 

Before writing the scraper I checked the relevant FAQs and Terms of Service; at the time this repository was created, nothing on the site prohibited or discouraged scraping. In addition, robots.txt on the site's server did not specify rules for automated crawlers to access the website. 100% of this data is available publicly on GiveSendGo.com and no private data was obtained or shared.

As I mention above, by default GiveSendGo does not anonymize donations which were intended to be anonymous. So as to avoid the sharing of PII unintentionally, this repository only contains a version of the data which anonymizes all contributions which have been given anonymously. That being said, the data on the website remains unredacted and the course of running the scraper will ultimately collect PII.

I provide no support or warranty for this scraper or the result data. I expect press scrutiny will likely cause architectural changes to the website.
