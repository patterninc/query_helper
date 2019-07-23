module ExampleQueries
  SQL_QUERIES = [
    {
      query: %(
        select c.id, c.name, c.age
        from children c
      ),
      model: Child,
      expected_sorts: ["id", "name", "age"],
      expected_filters: [
        {
          alias: "id",
          operator_codes: ["gte", "gt", "lte", "lt", "eql", "noteql"],
          class: Integer
        },
        {
          alias: "age",
          operator_codes: ["gte", "gt", "lte", "lt", "eql", "noteql"],
          class: Integer
        },
        {
          alias: "name",
          operator_codes: ["like"],
          class: String
        },
        {
          alias: "name",
          operator_codes: ["in", "notin"],
          class: String
        },
        {
          alias: "age",
          operator_codes: ["null"],
          class: TrueClass
        },
      ]
    },
    {
      query: %(
        select p.name, p.age, count(c.id) as children_count
        from parents p join children c on c.parent_id = p.id
        where p.age > 30
        group by p.name
        having count(c.id) > 3
        order by p.name
        limit 1
      ),
      model: Parent,
      expected_sorts: ["name", "age", "children_count"],
      expected_filters: [
        {
          alias: "age",
          operator_codes: ["gte", "gt", "lte", "lt", "eql", "noteql"],
          class: Integer
        },
        {
          alias: "name",
          operator_codes: ["like"],
          class: String
        },
        {
          alias: "name",
          operator_codes: ["in", "notin"],
          class: String
        },
        {
          alias: "age",
          operator_codes: ["null"],
          class: TrueClass
        },
        {
          alias: "children_count",
          operator_codes: ["gte", "gt", "lte", "lt", "eql", "noteql"],
          class: Integer
        },
      ]
    },
    {
      query: %(
        with children_count as (
          select p.id as parent_id, p.age, count(c.id) as children_count
          from parents p join children c on c.parent_id = p.id
          group by p.id
        ),
        max_age as (
          select p.id as parent_id, max(c.age) as max_age
          from parents p join children c on c.parent_id = p.id
          group by p.id
        )
        select p.name, c.children_count, m.max_age
        from parents p
        join children_count c on p.id = c.parent_id
        join max_age m on p.id = m.parent_id
      ),
      model: Child,
      expected_sorts: ["name", "children_count", "max_age"]
    },
    {
      query: %(
        select
          p.name,
          (
            select max(c2.age)
            from parents p2 join children c2 on c2.parent_id = p2.id
            where p2.id = p.id
            group by p2.id
          ) as max_age
        from parents p
      ),
      model: Child,
      expected_sorts: ["name", "max_age"]
    },
    {
      query: %(
        select c.id, c.name, c.age, p.name as parent_name
        from children c
        join parents p on p.id = c.parent_id
      ),
      model: Child,
      expected_sorts: ["id", "name", "age", "parent_name"]
    },
    {
      query: %(
        select
          p.name as parent_name,
          count(c.id) as count,
          COUNT(c.age) as count2,
          -- array_agg(c.name) as children_names,
          -- ARRAY_AGG(c.name) as children_names2,
          avg(c.age) as average,
          AVG(c.id) as average2,
          -- bit_and(c.age) as bit_and,
          -- BIT_AND(c.age) as bit_and2,
          -- bit_or(c.age) as bit_or,
          -- BIT_OR(c.age) as bit_or2,
          -- bool_and(true) as bool_and,
          -- BOOL_AND(true) as bool_and2,
          -- bool_or(true) as bool_or,
          -- BOOL_OR(true) as bool_or2,
          -- every(false) as every,
          -- EVERY(false) as every2,
          -- json_agg(c.*) as json_agg,
          -- JSON_AGG(c.*) as json_agg2,
          -- jsonb_agg(c.*) as jsonb_agg,
          -- JSONB_AGG(c.*) as jsonb_agg2,
          -- json_object_agg(c.*) as json_object_agg,
          -- JSON_OBJECT_AGG(c.*) as json_object_agg2,
          -- jsonb_object_agg(c.*) as jsonb_object_agg,
          -- JSONB_OBJECT_AGG(c.*) as jsonb_object_agg2,
          max(c.age) as max,
          MAX(c.id) as max2,
          min(c.age) as min,
          MIN(c.id) as min2,
          sum(c.age) as sum,
          SUM(c.id) as sum2
        from children c
        join parents p on p.id = c.parent_id
        group by p.name
      ),
      model: Child,
      expected_sorts: [
        "parent_name",
        "count",
        "count2",
        # "children_names",
        # "children_names2",
        "average",
        "average2",
        # "bit_and",
        # "bit_and2",
        # "bit_or",
        # "bit_or2",
        # "bool_and",
        # "bool_and2",
        # "bool_or",
        # "bool_or2",
        # "every",
        # "every2",
        # "every2",
        # "json_agg",
        # "json_agg2",
        # "jsonb_agg",
        # "jsonb_agg2",
        # "json_object_agg",
        # "json_object_agg2",
        # "jsonb_object_agg",
        # "jsonb_object_agg2",
        "max",
        "max2",
        "min",
        "min2",
        "sum",
        "sum2"
      ]
    },
  ]

end
