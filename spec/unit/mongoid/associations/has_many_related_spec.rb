require "spec_helper"

describe Mongoid::Associations::HasManyRelated do

  let(:block) do
    Proc.new do
      def extension
        "Testing"
      end
    end
  end

  let(:options) do
    Mongoid::Associations::Options.new(
      :name => :posts,
      :foreign_key => "person_id",
      :extend => block
    )
  end

  describe "#<<" do

    before do
      @child = stub
      @second = stub
      @children = [@child, @second]
    end

    context "when parent document has been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => false, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "saves and appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @child.expects(:save).returns(true)
        @association << @child
        @association.size.should == 1
      end

    end

    context "when parent document has not been saved" do

      context "when appending a non mongoid object" do

        before do
          @parent = stub(:id => "1", :new_record? => true, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
        end

        it "appends the child document" do
          @child.expects(:person_id=).with(@parent.id)
          @association << @child
          @association.size.should == 1
        end
      end

      context "when appending a mongoid document" do

        before do
          @criteria = mock
          @parent = stub(:id => "1", :new_record? => true, :class => Person)
          Post.expects(:all).returns(@criteria)
          @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
        end

        it "appends the child document" do
          @criteria.expects(:entries).returns([])
          @child.expects(:person_id=).with(@parent.id)
          @association << @child
          @association.size.should == 1
        end
      end

    end

    context "with multiple objects" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child documents" do
        @child.expects(:person_id=).with(@parent.id)
        @second.expects(:person_id=).with(@parent.id)
        @association << [@child, @second]
        @association.size.should == 2
      end

    end

  end

  describe "#build" do

    before do
      @criteria = mock
      @criteria.expects(:entries).returns([])
      @parent = stub(:id => "5", :class => Person, :new_record? => true)
      Post.expects(:all).returns(@criteria)
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    it "adds a new object to the association" do
      @association.build(:title => "Sassy")
      @association.size.should == 1
    end

    it "sets the parent object id on the child" do
      @association.build(:title => "Sassy")
      @association.first.person_id.should == @parent.id
    end

    it "returns the new object" do
      @association.build(:title => "Sassy").title.should == "Sassy"
    end

    it "sets the parent object reference on the child" do
      @association.build(:title => "Sassy")
      @association.first.person.should == @parent
    end

  end

  describe "#delete_all" do

    before do
      @criteria = mock
      @parent = stub(:id => "5", :class => Person, :new_record? => true)
      Post.expects(:all).twice.returns(@criteria)
      @parent.expects(:reset).with("posts").yields
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    it "deletes all of the associated object" do
      Post.expects(:delete_all).with(:conditions => { "person_id" => "5" }).returns(3)
      @association.delete_all.should == 3
    end
  end

  describe "#destroy_all" do

    before do
      @criteria = mock
      @parent = stub(:id => "5", :class => Person, :new_record? => true)
      Post.expects(:all).twice.returns(@criteria)
      @parent.expects(:reset).with("posts").yields
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    it "destroys all of the associated objects" do
      Post.expects(:destroy_all).with(:conditions => { "person_id" => "5" }).returns(3)
      @association.destroy_all.should == 3
    end
  end

  describe "#concat" do

    before do
      @child = stub
      @second = stub
    end

    context "when parent document has been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => false, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "saves and appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @child.expects(:save).returns(true)
        @association.concat(@child)
        @association.size.should == 1
      end

    end

    context "when parent document has not been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @association.concat(@child)
        @association.size.should == 1
      end

    end

    context "with multiple objects" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child documents" do
        @child.expects(:person_id=).with(@parent.id)
        @second.expects(:person_id=).with(@parent.id)
        @association.concat([@child, @second])
        @association.size.should == 2
      end

    end

  end

  describe "#create" do

    before do
      @post = mock
      @parent = stub(:id => "5", :class => Person, :new_record? => true)
      Post.expects(:all).returns([])
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      Post.expects(:instantiate).returns(@post)
    end

    it "builds and saves the new object" do
      @post.expects(:save).returns(true)
      @association.create(:title => "Sassy")
    end

    it "returns the new object" do
      @post.expects(:save).returns(true)
      @association.create(:title => "Sassy").should == @post
    end

  end

  describe "#create!" do

    before do
      @post = mock
      @parent = stub(:id => "5", :class => Person, :new_record? => true)
      Post.expects(:all).returns([])
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      Post.expects(:instantiate).returns(@post)
    end

    it "builds and saves the new object" do
      @post.expects(:save!).returns(true)
      @association.create!(:title => "Sassy")
    end

    it "returns the new object" do
      @post.expects(:save!).returns(true)
      @association.create!(:title => "Sassy").should == @post
    end

  end

  describe "#find" do

    before do
      @parent = stub(:id => "5", :class => Person)
      Post.expects(:all).returns([])
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    context "when finding by id" do

      before do
        @post = stub
      end

      it "returns the document in the array with that id" do
        Post.expects(:find).with("5").returns(@post)
        post = @association.find("5")
        post.should == @post
      end

    end

    context "when finding all with conditions" do

      before do
        @post = stub
      end

      it "passes the conditions to the association class" do
        Post.expects(:find).with(:all, :conditions => { :title => "Testing", :person_id => @parent.id }).returns([@post])
        posts = @association.find(:all, :conditions => { :title => "Testing" })
        posts.should == [@post]
      end

    end

    context "when finding first with conditions" do

      before do
        @post = stub
      end

      it "passes the conditions to the association class" do
        Post.expects(:find).with(:first, :conditions => { :title => "Testing", :person_id => @parent.id }).returns(@post)
        post = @association.find(:first, :conditions => { :title => "Testing" })
        post.should == @post
      end

    end

    context "when finding last with conditions" do

      before do
        @post = stub
      end

      it "passes the conditions to the association class" do
        Post.expects(:find).with(:last, :conditions => { :title => "Testing", :person_id => @parent.id }).returns(@post)
        post = @association.find(:last, :conditions => { :title => "Testing" })
        post.should == @post
      end

    end

  end

  describe ".initialize" do

    before do
      @document = Person.new
      @criteria = stub
      @first = stub(:person_id => @document.id)
      @second = stub(:person_id => @document.id)
      @related = [@first, @second]
      Post.expects(:all).with(:conditions => { "person_id" => @document.id }).returns(@related)
    end

    context "when related id has been set" do

      it "finds the object by id" do
        association = Mongoid::Associations::HasManyRelated.new(@document, options)
        association.should == @related
      end

    end

    context "when the options have an extension" do

      it "adds the extension module" do
        association = Mongoid::Associations::HasManyRelated.new(@document, options)
        association.extension.should == "Testing"
      end

    end

  end

  describe ".instantiate" do

    context "when related id has been set" do

      before do
        @document = Person.new
      end

      it "delegates to new" do
        Mongoid::Associations::HasManyRelated.expects(:new).with(@document, options, nil)
        association = Mongoid::Associations::HasManyRelated.instantiate(@document, options)
      end

    end

  end

  describe ".macro" do

    it "returns :has_many_related" do
      Mongoid::Associations::HasManyRelated.macro.should == :has_many_related
    end

  end

  describe "#push" do

    before do
      @child = stub
      @second = stub
    end

    context "when parent document has been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => false, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "saves and appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @child.expects(:save).returns(true)
        @association.push(@child)
        @association.size.should == 1
      end

    end

    context "when parent document has not been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @association.push(@child)
        @association.size.should == 1
      end

    end

    context "with multiple objects" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child documents" do
        @child.expects(:person_id=).with(@parent.id)
        @second.expects(:person_id=).with(@parent.id)
        @association.push(@child, @second)
        @association.size.should == 2
      end

    end

  end

  describe ".update" do

    before do
      @first = Post.new
      @second = Post.new
      @related = [@first, @second]
      @parent = Person.new
    end

    it "sets the related object id on the parent" do
      Mongoid::Associations::HasManyRelated.update(@related, @parent, options)
      @first.person_id.should == @parent.id
      @second.person_id.should == @parent.id
    end

    it "returns the related objects" do
      @proxy = Mongoid::Associations::HasManyRelated.update(@related, @parent, options)
      @proxy.target.should == @related
    end

  end

end
