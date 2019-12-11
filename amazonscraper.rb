require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'csv'

Capybara.default_driver = :poltergeist
Capybara.run_server = false

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, phantomjs_options: ['--load-images=false', '--disk-cache=false'], js_errors: false)
end

module GetPrice
  class WebScraper
    include Capybara::DSL

    def scraper(asin,price)

          browser = Capybara.current_session

          url_two = "https://www.amazon.com/gp/offer-listing/#{asin}/ref=olp_f_primeEligible?ie=UTF8&f_new=true&f_primeEligible=true"
          browser.visit url_two

          list = []
          list = browser.all('.olpSellerName').each { |seller| list << seller }
          puts "# of Prime sellers: #{list.count}"

          title = []
          browser.all('.a-size-large').each { |item| title << item }
          item_title = title[0].text
          puts ""
          puts "#{item_title}"
          puts ""
          
          amz_offer = []
          all_offers = browser.all('.olpOffer')
          all_offers.each { |offer| offer.has_selector?('img[alt="Amazon.com"]') ? amz_offer << offer.find('.olpOfferPrice') : amz_offer }

          amazon = browser.has_selector?('img[alt="Amazon.com"]') ? "Yes" : "No"
          if list.count != 0 && amazon == "Yes"     
            puts "Is Amazon a seller on the listing: #{amazon}. Price: #{amz_offer[0].text}"

            fba_price = []
            fba_price_two = []
            fba_price = browser.all('.olpOfferPrice').each { |price| fba_price << price }
            puts "Lowest FBA price: #{fba_price[0].text}."

          elsif list.count != 0 && amazon == "No" 
            fba_price = []
            fba_price_two = []
            fba_price = browser.all('.olpOfferPrice').each { |price| fba_price << price }
            puts "Lowest FBA price: #{fba_price[0].text}."
          else
            fba_price_two = []
            puts "Visit:" 
            puts "https://www.amazon.com/gp/offer-listing/#{asin}" 
            puts "to determine the nearest competitive price."
            print "What is the lowest MF price? $"
            lowest_mf = STDIN.gets.chomp
            fba_price_two << lowest_mf
          end
          
          puts ""
          if fba_price == nil
            fba_adj_price = fba_price_two[0]
          else
            fba_adj_price = fba_price[0].text   
          end

          amz_price_adj = amz_offer.empty? ? fba_adj_price : amz_offer[0].text
          amz_price_adj.slice!(0) unless fba_adj_price = fba_price_two[0]
          two_percent_off = amz_price_adj.to_f * 0.98
          three_percent_off = amz_price_adj.to_f * 0.97

          puts "2% lower than Amazon/FBA: $#{'%.2f' % two_percent_off}"
          # puts "3% lower than Amazon/FBA: $#{'%.2f' % three_percent_off}"

          # puts ""
          # print "Set your item price: $"
          item_price = two_percent_off
          # STDIN.gets.chomp
          # print "Product cost: $"
          product_cost = price


          url = "https://amzscout.net/fba-fee-calculator"
          browser.visit url
          browser.fill_in 'Paste here ASIN or product URL', with:"#{asin}"
          browser.click_button('Search')
          browser.find(:css, "input[data-bind$='product.price']").set("#{item_price}")
          browser.click_button('Calculate')
          browser.click_button('Calculate')
          fba_fee = browser.find('[class=fba-calc-data_static]').text
          product_weight = browser.find(:css, "span[data-bind$='product.shippingWeight']").text
          shipping_fee = product_weight.to_f * 0.50
          puts "Shipping Costs (based on average $.50/lb.): $#{'%.2f' % shipping_fee}"
          puts "FBA fees: $#{fba_fee}"

          net_profit = item_price.to_f - fba_fee.to_f - product_cost.to_f - shipping_fee.to_f
          percentage = (net_profit.to_f / item_price.to_f) * 100
          adj_net_profit = '%.2f' % net_profit
          puts "Net profit: $#{adj_net_profit} (#{percentage.round(2)}%)"

          puts ""

          puts "          *******Camelizer Info. - Price History*******"
          puts "                               Visit:" 
          puts "               camelcamelcamel.com/product/#{asin}"
          puts ""
          print "Historical Low: $"
          historical_low_price = STDIN.gets.chomp.to_f
          puts ""
          puts "          *******Camelizer Info. - Sales History*******"
          puts "                  Click on the 'Sales Rank' tab"
          puts ""
          print "High: "
          rank1 = STDIN.gets.chomp
          print "Current: "
          rank2 = STDIN.gets.chomp
          print "Low: "
          rank3 = STDIN.gets.chomp
          avg_sales_rank = rank2 
          ((rank1.to_f + rank2.to_f + rank3.to_f) / 3)
          puts ""
          puts "Average Sales Rank: #{avg_sales_rank.to_i}"

          url_three = "https://www.amazon.com/gp/product/#{asin}"
          browser.visit url_three
          category = browser.first(:css, "span[class$='a-list-item']").text
          puts "Amazon category: #{category}"
          
          puts ""

          puts "              *******JungleScout Info.*******"
          puts "                           Visit:" 
          puts "          https://www.junglescout.com/estimator/"
          puts "Click '#{category}' and input '#{avg_sales_rank.to_i}'."
          puts ""

          print "Estimated sales per mo.: "
          est_sales = STDIN.gets.chomp
          total_max_profit = est_sales.to_f * adj_net_profit.to_f
          
          exp_sales = list.count != 0 ? est_sales.to_i/(list.count + 1) : est_sales.to_i
          puts "Expected sales per mo. (if sharing the BuyBox): #{exp_sales.floor}"
          total_profit = exp_sales * adj_net_profit.to_f
          

          url_four = "https://amzscout.net/fba-fee-calculator"
          browser.visit url_four
          browser.fill_in 'Paste here ASIN or product URL', with:"#{asin}"
          browser.click_button('Search')
          browser.find(:css, "input[data-bind$='product.price']").set("#{'%.2f' % historical_low_price}")
          browser.click_button('Calculate')
          browser.click_button('Calculate')
          fba_fee_2 = browser.find('[class=fba-calc-data_static]').text
          product_weight = browser.find(:css, "span[data-bind$='product.shippingWeight']").text
          puts ""
          net_profit_2 = historical_low_price.to_f - fba_fee_2.to_f - product_cost.to_f - shipping_fee.to_f
          percentage_2 = (net_profit_2.to_f / historical_low_price.to_f) * 100
          adj_net_profit_2 = '%.2f' % net_profit_2
          puts "Net profit: $#{adj_net_profit} (#{percentage.round(2)}%)"
          puts "Net profit (based on lowest historical price): $#{adj_net_profit_2} (#{percentage_2.round(2)}%)"
          total_profit_2 = exp_sales * adj_net_profit_2.to_f
          
          puts "Expected profit per mo.: $#{'%.2f' % total_max_profit}"
          puts "Expected profit per mo. (if sharing the BuyBox): $#{'%.2f' % total_profit}"
          puts "Expected profit per mo. (based on lowest historical price): $#{'%.2f' % total_profit_2}"

          puts ""
          print "Expected profit margin (percentage): "
          exp_profit = STDIN.gets.chomp
          adj_exp_profit = exp_profit.to_f / 100
          exp_profit_margin = adj_exp_profit * item_price.to_f
          adj_net_profit_3 = item_price.to_f - fba_fee.to_f - shipping_fee.to_f
          exp_product_cost = adj_net_profit_3.to_f - exp_profit_margin.to_f
          puts "Desired product cost: $#{'%.2f' % exp_product_cost}"
          profit_adj_cost = adj_net_profit_3 - exp_product_cost
          adj_percentage = (profit_adj_cost.to_f / item_price.to_f) * 100
          profit_adj_cost_2 = '%.2f' % profit_adj_cost
          puts "Net profit (based on desired profit margin): $#{profit_adj_cost_2} (#{adj_percentage.round(2)}%)"
          adj_total_max_profit = est_sales.to_f * profit_adj_cost_2.to_f
          puts "Expected profit per mo. (based on desired profit margin): $#{'%.2f' % adj_total_max_profit}"

          input = nil

          while input != 2
            puts ""
            puts "1. Run another ASIN."
            puts "2. Exit."
            puts "Please make a selection:"
            puts ""
            
            input = gets.strip.to_i
            case input
              when 1
                asin = STDIN.gets.chomp
                GetPrice::WebScraper.new.scraper(asin)
              when 2
                puts "Day One."
              else
                puts "Please choose 1 or 2."
            end
          end
    end
  end
end

puts "Enter the ASIN for the product you want to look up."
print "ASIN: "
asin = STDIN.gets.chomp
print "Price: "
price = STDIN.gets.chomp
GetPrice::WebScraper.new.scraper(asin,price)