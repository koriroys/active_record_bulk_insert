require 'spec_helper'

describe SampleRecord do
 describe "bulk_insert" do
   it "inserts records into the DB" do
     ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
       params.should include("INSERT INTO \"sample_records\"")
       params.should include("Foo")
       params.should include("30")
     end.once
     SampleRecord.bulk_insert([{:name => "Foo", :age => 30}])
   end

   it "inserts records into the DB and increases count of records" do
     records = 5.times.map { |i| SampleRecord.new(:age => i + (30..50).to_a.sample, :name => "Foo#{i}").attributes }
     expect {SampleRecord.bulk_insert(records)}.to change{SampleRecord.count}.by(records.size)
   end

   it "inserts multiple records into the DB in a single insert statement" do
     records = 10.times.map { |i| {:age => 4, :name => "Foo#{i}"} }

     ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
       matchdata = params.match(/insert into "sample_records"/i)
       matchdata.to_a.count.should == 1
       records.each do |record|
         params.should include(record[:age].to_s)
         params.should include(record[:name])
       end
     end.once

     SampleRecord.bulk_insert(records)
   end

   it "relies on the DB to provide primary_key if :use_provided_primary_key is false or nil" do
     records = 10.times.map { |i| SampleRecord.new(:id => 10000 + i, :age => 4, :name => "Foo#{i}") }

     ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
       records.each do |record|
         params.should_not include(record.id.to_s)
       end
     end

     SampleRecord.bulk_insert(records)
   end

   it "uses provided primary_key if :use_provided_primary_key is true" do
     records = 10.times.map { |i| SampleRecord.new(:id => 10000 + i, :age => 4, :name => "Foo#{i}") }

     SampleRecord.bulk_insert(records, :use_provided_primary_key => true)
     records.each do |record|
       SampleRecord.exists?(:id => record.id).should be_true
     end
   end

   it "support insertion of ActiveRecord objects" do
     records = 10.times.map { |i| SampleRecord.new(:age => 4, :name => "Foo#{i}") }

     ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
       matchdata = params.match(/insert into "sample_records"/i)
       matchdata.to_a.count.should == 1
       records.each do |record|
         params.should include(record.age.to_s)
         params.should include(record.name)
       end
     end.once

     SampleRecord.bulk_insert(records)
   end

   context "validations" do
     it "should not persist invalid records if ':validate => true' is specified" do
       SampleRecord.send(:validates, :name, :presence => true)
       expect {SampleRecord.bulk_insert([:age => 30], :validate => true)}.to_not change{SampleRecord.count}
     end
   end
 end

 describe "bulk_insert_in_batches" do
   it "allows you to specify a batch_size" do
     records = 10.times.map { |i| SampleRecord.new(:age => 4, :name => "Foo#{i}").attributes }

     ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
       params.should include("INSERT INTO \"sample_records\"")
     end.exactly(5).times

     SampleRecord.bulk_insert_in_batches(records, :batch_size => 2)
   end
 end
end
