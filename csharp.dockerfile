# Используем официальный образ ASP.NET Core
FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["SimpleApp/SimpleApp.csproj", "SimpleApp/"]
RUN dotnet restore "SimpleApp/SimpleApp.csproj"
COPY . .
WORKDIR "/src/SimpleApp"
RUN dotnet build "SimpleApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SimpleApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SimpleApp.dll"]
