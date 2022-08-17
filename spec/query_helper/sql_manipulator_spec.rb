# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryHelper::SqlManipulator do
  subject(:manipulator) { described_class.new(sql: sql,
                                              where_clauses: where_clauses,
                                              having_clauses: having_clauses,
                                              qualify_clauses: qualify_clauses,
                                              order_by_clauses: order_by_clauses,
                                              include_limit_clause: include_limit_clause,
                                              additional_select_clauses: additional_select_clauses).build }
  let(:sql) { "SELECT * FROM TESTING" }
  let(:where_clauses) { [] }
  let(:having_clauses) { [] }
  let(:qualify_clauses) { [] }
  let(:order_by_clauses) { [] }
  let(:include_limit_clause) { false }
  let(:additional_select_clauses) { [] }
  let(:parser) { QueryHelper::SqlParser.new(sql) }

  describe "#build" do
    context "add where_clauses" do
      let(:where_clauses) { ["id = 1", "name = 'hh'"] }

      it "adds where clause to query" do
        expect(manipulator).to eq("SELECT * FROM TESTING where id = 1 and name = 'hh'")
      end
    end

    context "add having_clauses" do
      let(:having_clauses) { ["COUNT(*) > 1"] }

      it "adds having clause to query" do
        expect(manipulator).to eq("SELECT * FROM TESTING having COUNT(*) > 1")
      end
    end

    context "add include_limit_clause" do
      let(:include_limit_clause) { true }

      it "adds limit and offset clause to query" do
        expect(manipulator).to eq("SELECT * , count(*) over () as _query_full_count FROM TESTING limit :limit offset :offset")
      end

      context "when limit and offset is exist in query" do
        let(:sql) { "SELECT * FROM TESTING limit :limit offset :offset" }

        it "adds limit and offset clause to query" do
          expect(manipulator).to eq("SELECT * , count(*) over () as _query_full_count FROM TESTING limit :limit offset :offset")
        end
      end
    end

    context "add order_by_clauses" do
      let(:order_by_clauses) { ["id desc"] }

      it "adds order clause to query" do
        expect(manipulator).to eq("SELECT * FROM TESTING order by id desc")
      end

      context "when order is exist in query" do
        let(:sql) { "SELECT * FROM TESTING order name desc" }

        it "adds order clause to query" do
          expect(manipulator).to eq("SELECT * FROM TESTING order name desc order by id desc")
        end
      end
    end

    context "add additional_select_clauses" do
      let(:additional_select_clauses) { ["title AS name"] }

      it "adds additional select statement clause to query" do
        expect(manipulator).to eq("SELECT * , title AS name FROM TESTING")
      end
    end

    context "add qualify_clauses" do
      let(:qualify_clauses) { ["percentage > 1.0"] }

      it "adds qualify clause to query" do
        expect(manipulator).to eq("SELECT * FROM TESTING qualify percentage > 1.0")
      end

      it "verifies qualify clause to query at the correct position, as per the query life cycle" do
        expect(parser.insert_qualify_index).to eq(manipulator.index(' qualify'))
      end

      context "when paginated results" do
        let(:include_limit_clause) { true }
        context "when using mutliple statements" do
          let(:sql) { "report as (select * from reports) SELECT report.* FROM report" }

          it "adds qualify clause to query" do
            expect(manipulator).to eq("report as (select * from reports), qualified_results AS ( SELECT report.* FROM report qualify percentage > 1.0 limit :limit offset :offset ) SELECT qualified_results.*, count(*) over () as _query_full_count FROM qualified_results")
          end
        end

        context "when call repeat with same query" do
          let(:qualify_clauses) { [] }
          let(:sql) { "qualified_results AS ( SELECT report.* FROM report qualify percentage > 1.0 limit :limit offset :offset ) SELECT qualified_results.*, count(*) over () as _query_full_count FROM qualified_results" }

          it "adds qualify clause to query" do
            expect(manipulator).to eq("WITH qualified_results AS ( SELECT report.* FROM report qualify percentage > 1.0 limit :limit offset :offset ) SELECT qualified_results.*, count(*) over () as _query_full_count FROM qualified_results")
          end
        end

        context "when using single query" do
          let(:sql) { "SELECT * FROM TESTING" }

          it "adds qualify clause to query" do
            expect(manipulator).to eq("WITH qualified_results AS ( SELECT * FROM TESTING qualify percentage > 1.0 limit :limit offset :offset ) SELECT qualified_results.*, count(*) over () as _query_full_count FROM qualified_results")
          end
        end
      end
    end
  end
end
