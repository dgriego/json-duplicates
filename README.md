# Setup for running the script

## Setup Ruby Environment

The Ruby version is specified in the .ruby-version file. I use `rbenv` to
configure the ruby version on my system, but you can use either `rvm` or `rbenv` to
set the correct ruby version for this script.

If you don't have either install, you can install `rbenv` [here](https://github.com/rbenv/rbenv#installation)

## Setup and run script

After the `ruby` version has been set, follow these steps to run the script:

from the root of the repo:

1. clone the repo
2. `cd json-duplicates`
3. `gem install bundler`
4. `bundle install`
5. `./deduplicate_leads`

## Clean up script

To remove all generated files and reset the change log, run:

`./clean_files`

## Run Test suite

There are assumptions made and I didn't cover every edge case, including that
the leads will be in the form of JSON and will always be in the structure.  The
tests aim to cover core elements of the Lead class behavior

`ruby tests/sanitize_leads_spec.rb`

## When the script is run, it will produce the following results:
- Output the valid leads as json into a generated file labeled "valid-leads"
  with a timestamp
- Create an entry in the change_log.txt file with a representation
  of the input (before) and output (after) with a text summary of valid and removed
