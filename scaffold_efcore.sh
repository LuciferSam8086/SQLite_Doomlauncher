#!/bin/bash
set -euo pipefail

EF_VERSION="11.0.0"
PROJECT_NAME="DoomLauncher"
CONTEXT_NAME="DoomLauncherDbContext"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="doomlauncher.db"

export PATH="$PATH:$HOME/.dotnet/tools"

command -v dotnet >/dev/null 2>&1 || { echo "ERROR: dotnet SDK not found on PATH" >&2; exit 1; }

if [ ! -f "$PROJECT_DIR/$DB_FILE" ]; then
    echo "ERROR: $PROJECT_DIR/$DB_FILE not found. Generate it first: python3 generate_db.py" >&2
    exit 1
fi

cd "$PROJECT_DIR"

echo "==> Ensuring dotnet-ef $EF_VERSION tool"
if ! dotnet tool list --global 2>/dev/null | awk '{print $1, $2}' | grep -q "^dotnet-ef 11\."; then
    dotnet tool install --global dotnet-ef --version "$EF_VERSION" 2>/dev/null \
        || dotnet tool update --global dotnet-ef --version "$EF_VERSION"
fi

echo "==> Creating .NET project (if missing)"
if ! ls ./*.csproj >/dev/null 2>&1; then
    dotnet new classlib -n "$PROJECT_NAME" -o .
    rm -f Class1.cs
fi

if grep -q "<ImplicitUsings>enable</ImplicitUsings>" ./*.csproj; then
    sed -i 's/<ImplicitUsings>enable</<ImplicitUsings>disable</' ./*.csproj
elif ! grep -q "ImplicitUsings" ./*.csproj; then
    sed -i 's#</Project>#  <PropertyGroup><ImplicitUsings>disable</ImplicitUsings></PropertyGroup>\n</Project>#' ./*.csproj
fi

echo "==> Adding EF Core $EF_VERSION packages"
grep -q "Microsoft.EntityFrameworkCore.Sqlite" ./*.csproj \
    || dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version "$EF_VERSION"
grep -q "Microsoft.EntityFrameworkCore.Design" ./*.csproj \
    || dotnet add package Microsoft.EntityFrameworkCore.Design --version "$EF_VERSION"

grep -q "^obj/$" .gitignore 2>/dev/null || printf '\nbin/\nobj/\n' >> .gitignore

echo "==> Scaffolding entities from $DB_FILE"
STASH=""
if [ -f "$PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs" ]; then
    STASH="$(mktemp)"
    mv "$PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs" "$STASH"
fi
restore_partial() {
    if [ -n "$STASH" ]; then
        mv "$STASH" "$PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs"
        STASH=""
    fi
}
trap restore_partial EXIT

rm -rf "$PROJECT_DIR/Models" "$PROJECT_DIR/Data/Generated"
dotnet ef dbcontext scaffold \
    "Data Source=$DB_FILE" \
    Microsoft.EntityFrameworkCore.Sqlite \
    --context "$CONTEXT_NAME" \
    --context-dir Data/Generated \
    --context-namespace "$PROJECT_NAME.Data" \
    --output-dir Models \
    --no-pluralize \
    --no-onconfiguring \
    --force

restore_partial

echo "==> Creating path-parameter partial (if missing)"
mkdir -p "$PROJECT_DIR/Data"
if [ ! -f "$PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs" ]; then
    cat > "$PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs" <<'EOF'
using Microsoft.EntityFrameworkCore;

namespace __NS__;

public partial class __CONTEXT__
{
    private readonly string? _dbPath;

    public __CONTEXT__()
    {
    }

    public __CONTEXT__(string dbPath)
    {
        _dbPath = dbPath;
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlite($"Data Source={_dbPath ?? "__DB__"}");
        }
    }
}
EOF
    sed -i "s/__NS__/${PROJECT_NAME}.Data/; s/__CONTEXT__/$CONTEXT_NAME/; s/__DB__/$DB_FILE/" "$PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs"
fi

echo "==> Building project"
dotnet build --nologo -v q

echo ""
echo "Scaffold complete:"
echo "  Entities  : $PROJECT_DIR/Models"
echo "  DbContext : $PROJECT_DIR/Data/Generated/${CONTEXT_NAME}.cs"
echo "  Path ctor : $PROJECT_DIR/Data/${CONTEXT_NAME}.path.cs"
