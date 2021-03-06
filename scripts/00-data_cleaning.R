#### Preamble ####
# Purpose: Get and clean data on school info and student demographics from Ontario's Data Catalogue
# Author: Najma Osman
# Date: 2 February 2021
# Contact: naj.osman@mail.utoronto.ca / najmamosman@gmail.com
# License: MIT
# Pre-requisites: None



#### setup ####
library(here)
library(janitor)
library(tidyverse)
library(readxl)
library(writexl)
library(curl)

#### get and read in raw data #### 
  # Data from Ontario Data Catalogue (https://data.ontario.ca/dataset/school-information-and-student-demographics) #
url <- 
  "https://data.ontario.ca/dataset/d85f68c5-fcb0-4b4d-aec5-3047db47dcd5/resource/602a5186-67f5-4faf-94f3-7c61ffc4719a/download/new_sif_data_table_2018_2019prelim_en_december.xlsx"
destfile <- 
  here("inputs/data/new_sif_data_table_2018_2019prelim_en_december.xlsx")
curl::curl_download(url, destfile)
# read into R
raw_data <- 
  read_excel(destfile)

#### data cleaning ####

# clean row names #

clean_names <- 
  janitor::clean_names(raw_data)

# reduced data; #
  # removing rows associated with:
    # * containing elementary schools,
    # * containing schools where the language is French, as they have different tests which are covered in a separate dataset,
    # * having codes NA, NR, or ND in columns to do with Grade 9 EQAO/mathematics achievement of provincial standard and/or the Grade 10 literacy test (OSSLT),
    # * containing code SP in columns to do with household income and/or percentage of students whose parents have some university education.

filter_data <-
  clean_names %>%
  filter(school_level == "Secondary", school_language == "English") %>%
  filter(percentage_of_students_whose_parents_have_some_university_education != "SP", 
         percentage_of_school_aged_children_who_live_in_low_income_households != "SP") %>%
  filter(change_in_grade_9_academic_mathematics_achievement_over_three_years != "NA", 
         change_in_grade_9_academic_mathematics_achievement_over_three_years != "N/R", 
         change_in_grade_9_academic_mathematics_achievement_over_three_years != "N/D") %>%
  filter(change_in_grade_9_applied_mathematics_achievement_over_three_years != "NA", 
         change_in_grade_9_applied_mathematics_achievement_over_three_years != "N/R", 
         change_in_grade_9_applied_mathematics_achievement_over_three_years != "N/D") %>%
  filter(change_in_grade_10_osslt_literacy_achievement_over_three_years != "NA", 
         change_in_grade_10_osslt_literacy_achievement_over_three_years != "N/R", 
         change_in_grade_10_osslt_literacy_achievement_over_three_years != "N/D") %>%
  filter(percentage_of_grade_9_students_achieving_the_provincial_standard_in_academic_mathematics != "NA", 
         percentage_of_grade_9_students_achieving_the_provincial_standard_in_academic_mathematics != "N/R", 
         percentage_of_grade_9_students_achieving_the_provincial_standard_in_academic_mathematics != "N/D") %>%
  filter(percentage_of_grade_9_students_achieving_the_provincial_standard_in_applied_mathematics != "NA", 
         percentage_of_grade_9_students_achieving_the_provincial_standard_in_applied_mathematics != "N/R", 
         percentage_of_grade_9_students_achieving_the_provincial_standard_in_applied_mathematics != "N/D") 
  

  # remove the following columns/select all the others (probably easier): 
      #  * location information: board number, board name, board type, school number, building suite, P.O. Box, Street, postal code, province, latitude, longitude,
      # * school info: school type, school special condition code (e.g., Alternative, Adult, NA), grade range, enrolment, school language,
      # * contact information: phone number, fax number, school website, board website
      # * testing information: grade 3 and 6 results (EQAO, achievement of provincial standard (percentage of student and change over 3 years))

select_data <-
  filter_data %>%
  select(-c(board_number, board_type, school_number, building_suite, p_o_box, street, postal_code, municipality, province, latitude, longitude,
            school_type, school_special_condition_code, school_language, school_level, grade_range,
            phone_number, fax_number, school_website, board_website)) %>%
  select(-c(percentage_of_students_whose_first_language_is_not_english, percentage_of_students_whose_first_language_is_not_french, percentage_of_students_who_are_new_to_canada_from_a_non_english_speaking_country, percentage_of_students_who_are_new_to_canada_from_a_non_french_speaking_country)) %>%
  select(-c(change_in_grade_3_reading_achievement_over_three_years, change_in_grade_3_writing_achievement_over_three_years, change_in_grade_3_mathematics_achievement_over_three_years, 
            percentage_of_grade_3_students_achieving_the_provincial_standard_in_mathematics, percentage_of_grade_3_students_achieving_the_provincial_standard_in_reading, percentage_of_grade_3_students_achieving_the_provincial_standard_in_writing,
            change_in_grade_6_mathematics_achievement_over_three_years, change_in_grade_6_reading_achievement_over_three_years, change_in_grade_6_writing_achievement_over_three_years,
            percentage_of_grade_6_students_achieving_the_provincial_standard_in_mathematics, percentage_of_grade_6_students_achieving_the_provincial_standard_in_writing, percentage_of_grade_6_students_achieving_the_provincial_standard_in_reading)) %>%
  select(-c(extract_date))

#### convert character columns which contain numbers to numeric ####

# remove % symbols from columns on achieving mathematics standard/OSSLT pass attempts and convert to numeric

select_data$percentage_of_grade_9_students_achieving_the_provincial_standard_in_academic_mathematics <- as.numeric(as.character(gsub("%", "", select_data$percentage_of_grade_9_students_achieving_the_provincial_standard_in_academic_mathematics)))
select_data$percentage_of_grade_9_students_achieving_the_provincial_standard_in_applied_mathematics <- as.numeric(as.character(gsub("%", "", select_data$percentage_of_grade_9_students_achieving_the_provincial_standard_in_applied_mathematics)))
select_data$percentage_of_students_that_passed_the_grade_10_osslt_on_their_first_attempt <- as.numeric(as.character(gsub("%", "", select_data$percentage_of_students_that_passed_the_grade_10_osslt_on_their_first_attempt)))

# convert remaining character columns that should be numeric

select_data$enrolment <- as.numeric(as.character(select_data$enrolment))
select_data$percentage_of_students_receiving_special_education_services <- as.numeric(as.character(select_data$percentage_of_students_receiving_special_education_services))
select_data$percentage_of_students_identified_as_gifted <- as.numeric(as.character(select_data$percentage_of_students_identified_as_gifted))
select_data$change_in_grade_9_academic_mathematics_achievement_over_three_years <- as.numeric(as.character(select_data$change_in_grade_9_academic_mathematics_achievement_over_three_years))
select_data$change_in_grade_9_applied_mathematics_achievement_over_three_years <- as.numeric(as.character(select_data$change_in_grade_9_applied_mathematics_achievement_over_three_years))
select_data$change_in_grade_10_osslt_literacy_achievement_over_three_years <- as.numeric(as.character(select_data$change_in_grade_10_osslt_literacy_achievement_over_three_years))
select_data$percentage_of_school_aged_children_who_live_in_low_income_households <- as.numeric(as.character(select_data$percentage_of_school_aged_children_who_live_in_low_income_households))
select_data$percentage_of_students_whose_parents_have_some_university_education <- as.numeric(as.character(select_data$percentage_of_students_whose_parents_have_some_university_education))

#### save cleaned/reduced data set ####

writexl::write_xlsx(select_data, here("outputs/data/cleaned_data.xlsx"), col_names = TRUE)