require "test_helper"

describe MerchantsController do
  describe "logged out" do
    describe "index" do
      it "responds with success when there are many users saved" do
        # Act
        get merchants_path
        # Assert
        must_respond_with :success
      end

      it "responds with success when there are no merchants saved" do
        Merchant.delete_all
        # Act
        get merchants_path
        # Assert
        must_respond_with :success
      end
    end

    describe "show" do
      it "responds with success when showing an existing valid merchant" do
        # Arrange
        id = Merchant.find_by_id(merchants(:test).id)[:id]

        # Act
        get merchant_path(id)

        # Assert
        must_respond_with :success

      end

      it "responds with a redirect to the merchants page with an invalid id" do
        # Act
        get merchant_path(-1)
        # Assert
        must_redirect_to merchants_path
      end
    end

    describe "dashboard" do
      it "prevents non logged in users from accessing dashboard" do
        get dashboard_path

        must_redirect_to root_path

      end
    end

    describe "edit" do
      it "blocks non-logged in users" do
        get edit_merchant_path(merchants(:test).id)

        must_redirect_to root_path
      end
    end

    describe "update" do
      let (:edit_merchant_data) {
        {
          merchant: {username: "boomer",
                     email: "sooner@boomer.com"}
        }
      }
      it "blocks non signed in merchants" do
        expect{
          patch merchant_path(merchants(:test).id), params: edit_merchant_data
        }.wont_change "Merchant.count"

        must_redirect_to root_path

        expect(merchants(:test).username).must_equal "testing"
        expect(merchants(:test).email).must_equal "test@test.com"
      end
    end
  end

  describe "login/out functions " do
    describe "create" do
      it "logs in an existing user" do
        start_count = Merchant.count
        mer = merchants(:test)

        perform_login(mer)
        must_redirect_to dashboard_path
        expect(session[:user_id]).must_equal  mer.id

        # Should *not* have created a new user
        expect(Merchant.count).must_equal start_count
      end
      it "creates an account for a new user and redirects to the root route" do
      end

      it "redirects to the login route if given invalid user data" do
      end
    end
    describe "destroy" do
      # needs OAuth
    end
  end
  describe "active session only functions" do
    before do
      @merchant1 = Merchant.create(username: "m1", email: "m1@email.com")
      @merchant2 = Merchant.create(username: "m2", email: "m2@email.com")
      @login_data = {merchant: {username: @merchant1.username, email:@merchant1.email} }
    end
    let (:edit_merchant_data) {
      {
        merchant: {username: "boomer",
                   email: "sooner@boomer.com"}
      }
    }
    # the following functions require login
    describe "dashboard" do
      it "allows logged in users to access dashboard" do
        post login_path(@login_data)
        get dashboard_path

        # this is a little redundant, but one thing to note is that the route is written so that
        # this only applies to the CURRENT user -- you can never access another merchant's dashboard but your
        # own
        expect(Merchant.find_by(id: session[:user_id])).must_equal @merchant1

        must_respond_with :success
      end
    end
    describe "edit" do
      # testing both invalid cases (after login, if not logged in doesn't even reach this point i think)
      # because they technically come from difference sources
      # even though they all redirect to the same path
      it "blocks invalid merchants" do
        post login_path(@login_data)

        get edit_merchant_path(-1)

        must_redirect_to dashboard_path

      end
      it "prevents a logged in merchant from accessing another merchant's edit page" do
        post login_path(@login_data)

        get edit_merchant_path(@merchant2.id)

        must_redirect_to dashboard_path
      end
      it "permits access for a logged in user to access their edit page" do
        post login_path(@login_data)

        get edit_merchant_path(@merchant1.id)

        must_respond_with :success
      end
    end

    describe "update" do
      it "updates a merchant's info when valid parameters are input" do
        post login_path(@login_data)

        # Act-Assert
        expect{
          patch merchant_path(@merchant1.id), params: edit_merchant_data
        }.wont_change "Merchant.count"

        must_redirect_to dashboard_path

        edited_merchant = Merchant.find_by(username: edit_merchant_data[:merchant][:username])
        expect(edited_merchant.email).must_equal edit_merchant_data[:merchant][:email]
      end
      it "doesn't update a non-existent merchant's info " do
        post login_path(@login_data)

        expect{
          patch merchant_path(-1), params: edit_merchant_data
        }.wont_change "Merchant.count"

        must_redirect_to dashboard_path
      end
      it "doesn't update the merchant if they're not the logged in merchant" do
        post login_path(@login_data)

        expect{
          patch merchant_path(@merchant2.id), params: edit_merchant_data
        }.wont_change "Merchant.count"

        must_redirect_to dashboard_path

        expect(@merchant2.username).must_equal "m2"
        expect(@merchant2.email).must_equal "m2@email.com"
      end

      it "doesn't update a merchant's info when invalid parameters are input" do
        post login_path(@login_data)

        edit_merchant_data[:merchant][:username] = nil

        # Act-Assert
        expect{
          patch merchant_path(@merchant1.id), params: edit_merchant_data
        }.wont_change "Merchant.count"

        must_respond_with :bad_request
        expect(@merchant1.username).must_equal "m1"
        expect(@merchant1.email).must_equal "m1@email.com"
      end

    end
  end
end
