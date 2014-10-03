# UseCase your code


## Installation

[![Build Status](https://secure.travis-ci.org/tdantas/usecasing.png)](http://travis-ci.org/tdantas/usecasing)
[![Dependency Status](https://gemnasium.com/tdantas/usecasing.svg)](https://gemnasium.com/tdantas/usecasing)
[![Coverage Status](https://coveralls.io/repos/tdantas/usecasing/badge.png)](https://coveralls.io/r/tdantas/usecasing)
[![Gem Version](https://badge.fury.io/rb/usecasing.svg)](http://badge.fury.io/rb/usecasing)

Add this line to your application's Gemfile:

  	gem 'usecasing'

And then execute:

    $ bundle

### Usage

Let's build a Invoice System, right ?
So the product owner will create some usecases/stories to YOU.

Imagine this usecase/story:

````
As a user I want to finalize an Invoice and an email should be delivered to the customer.
````

Let's build a controller

````
	class InvoicesController < ApplicationController

		def finalize

		    params[:current_user] = current_user
   		    # params = { invoice_id: 123 , current_user: #<User:007> }
			context = FinalizeInvoiceUseCase.perform(params)

			if context.success?
				redirect_to invoices_path(context.invoice)
			else
				@errors = context.errors
				redirect_to invoices_path
			end

		end

	end
````

Ok, What is FinalizeInvoiceUseCase ?

FinalizeInvoiceUseCase will be responsible for perform the Use Case/Story.
Each usecase should satisfy the [Single Responsability Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle) and to achieve this principle, one usecase depends of others usecases building a Chain of Resposability.


````

	class FinalizeInvoiceUseCase < UseCase::Base
		depends FindInvoice, ValidateToFinalize, FinalizeInvoice, SendEmail
	end

````

IMHO, when I read this Chain I really know what this class will do.
astute readers will ask: How FindInvoice pass values to ValidateToFinalize ?

When we call in the Controller *FinalizeInvoiceUseCase.perform* we pass a parameter (Hash) to the usecase.

This is what we call context, the usecase context will be shared between all chain.

````
	class FindInvoice < UseCase::Base

		def before
			@user = context.curent_user
		end

		def perform

			# we could do that in one before_filter
			invoice = @user.invoices.find(context.invoice_id)

			# asign to the context make available to all chain
			context.invoice = invoice

		end

	end
````

Is the invoice valid to be finalized ?

````
	class ValidateToFinalize < UseCase::Base

		def perform
			#failure will stop the chain flow and mark the context as error.

			failure(:validate, "#{context.invoice.id} not ready to be finalized") unless valid?
		end

		private
		def valid?
			#contextual validation to finalize an invoice
		end
	end

````

So, after validate, we already know that the invoice exists and it is ready to be finalized.

````
	class FinalizeInvoice < UseCase::Base

		def before
			@invoice = context.invoice
		end

		def perform
			@invoice.finalize! #update database with finalize state
			context.customer = invoice.customer
		end

	end
````

Oww, yeah, let's notify the customer

````
	class SendEmail < UseCase::Base

		def perform
			to = context.customer.email

			# Call whatever service
			EmailService.send('customer_invoice_template', to, locals: { invoice: context.invoice } )
		end

	end
````

#### Stopping the UseCase dependencies Flow

There are 2 ways to stop the dependency flow.
  - stop! ( stop the flow without marking the usecase with error )
  - failure ( stop the flow but mark the usecase with errors )


Imagine a Read Through Cache Strategy.
How can we stop the usecase flow without marking as failure ?

````
   class ReadThrough < UseCase::Base
      depends MemCacheReader, DataBaseReader, MemCacheWriter
   end

   class MemCacheReader < UseCase::Base
     def perform
       context.data = CacheAdapter.read('key')
       stop! if context.data
     end
   end

   class DataBaseReader < UseCase::Base
     def perform
       context.data = DataBase.find('key')
     end
   end

   class MemCacheWriter < UseCase::Base
     def perform
       CacheAdapter.write('key', context.data);
     end
   end

````

#### Execution order configuration

Given the following UseCase called SampleCase, which has a dependency on UseCase
AnotherSampleCase:

        class SampleCase < UseCase::Base
          depends AnotherSampleCase

          def before
          end

          def perform
          end
        end

By default the execution order will be:

  * first execute dependent UseCases (in this case AnotherSampleCase)
  * next execute logic in method before if any
  * execute logic in method perform if any

It's possible to change this execution order so that it executes in the
following order:

  * first execute logic in method before if any
  * next execute dependent UseCases (in this case AnotherSampleCase)
  * lastly execute logic in method perform if any

To do so just configure your UseCase before using it, as follows:

        UseCase.configure do |config|
          config.before_depends = true
        end

#### Setters and Getters for context

As mentioned previously values passed to UseCases are made available by means of
an object called 'context', as in the following example UseCase:

        class BuildCalendar < UseCase::Base
          def perform
            context.calendar =
              context.current_user.calendar.build(calendar_attributes)

            unless context.calendar.valid?
              failure(:failure, 'invalid calendar attributes')
            else
              context.success_message = 'calendar is valid'
            end
          end
        end

In order to help access these values it's possible to indicate, during UseCase
definition, setters and getters for attributes of context, similar to ruby's
attr_* notation. So we could rewrite the previous UseCase as follows:

        class SampleCase < UseCase::Base
          context_reader :current_user, :calendar_attributes
          context_writer :success_message
          context.accessor :calendar

          def perform
            # we're invoking a setter method, don't forget to use self
            self.calendar = current_user.build(calendar_attributes)

            unless calendar.valid?
              failure(:failure, 'invalid calendar attributes')
            else
              self.success_message = 'calendar is valid'
            end
          end
        end

#### Flow control

There might be cases were we need more control over the execution chain, as in
the execution chain changing depending on the result of each UseCase, imagine the
following case:

  * check if user credentials are valid
  * if valid keep going
  * if invalid and if it's the fifth retry we send an email to admin

This requires an if condition before invoking the UseCase to check if email
should be sent or not. If it is to send email we could manually handle the
UseCase invocation, or you could use method 'invoke!':

        class ValidateUserCredentials < UseCase::Base
          context_reader :credentials
          context_writer :admin_email_body

          def perform
            unless credentials_valid?
              failure(:failure, 'invalid credentials')

              if too_many_retries?
                self.admin_email_body = "#{credentials.email} tried too many times!"
                invoke! SendEmailToAdmin
              end
            end
          end

          def credentials_valid?
            # check if credentials are valid
          end
        end

This will invoke UseCase SendEmailToAdmin with the current context object.

We can also control the flow with method 'skip!'. This method is similar to
method 'stop!' where it stops the execution chain, but it only stops the
execution chain of the current UseCase (the following case is only applicable
when UseCase is configured with the execution order before -> depends -> perform):

        class CreateEventBase < UseCase::Base
          depends CreateEvent, SetAlarm, RaiseSuccess
        end

        class SetAlarm < UseCase::Base
          context_reader :event

          def before
            skip! unless event.set_alarm?
          end

          depends SendEmail

          def perform
            # set alarm
          end
        end

For this example what happens when during the invocation of CreateEventBase.perform
the method 'skip!' in SetAlarm#before is invoked? The UseCase SetAlarm and its
dependent UseCases will not be invoked, without interrupting the execution chain,
meaning that RaiseSuccess will still be invoked.

Let me know what do you think about it.

#### UseCase::Base contract

````
  # None of those methods are required.


	class BusinessRule < UseCase::Base

	  def before
	    # executed before perform
	  end

	  def perform
	    # execute the responsability that you want
	  end

	  def rollback
	   # Will be called only on failure
	  end

	end


````




#### TODO

 Create real case examples (40%)



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
