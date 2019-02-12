const {
  buildSchema,
  buildClientSchema,
  printSchema,
  getIntrospectionQuery
} = require("graphql");
const fs = require("fs");

let src = null;
let out = null;

process.argv.forEach(function(val, index, array) {
  if (val === "src") {
    src = array[index + 1];
  }
  switch (val) {
    case "--src":
      src = array[index + 1];
      break;
    case "--out":
      out = array[index + 1];
      break;
  }
});

if (!src) {
  console.error("must provide src path");
  return;
}

if (!out) {
  console.error("must provide out path");
  return;
}

function writeSchema(src, out) {
  const fileContent = fs.readFileSync(src, "utf-8");

  if (!fileContent) {
    console.error("no schema found");
    return;
  }

  const { data } = JSON.parse(fileContent);

  const clientSchema = buildClientSchema(data);

  const graphqlSchemaString = printSchema(clientSchema);
  const str = graphqlSchemaString.replace(/""".{1,}"""/g, "");
  const str1 = str.replace(/"""\n{1,}.{1,}\n{1,}"""/g, "");

  fs.writeFileSync(out, str1);
}

writeSchema(src, out);
