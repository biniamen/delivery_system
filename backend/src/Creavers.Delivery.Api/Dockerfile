FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["Directory.Build.props", "."]
COPY ["backend/src/Creavers.Delivery.Domain/Creavers.Delivery.Domain.csproj", "backend/src/Creavers.Delivery.Domain/"]
COPY ["backend/src/Creavers.Delivery.Application/Creavers.Delivery.Application.csproj", "backend/src/Creavers.Delivery.Application/"]
COPY ["backend/src/Creavers.Delivery.Infrastructure/Creavers.Delivery.Infrastructure.csproj", "backend/src/Creavers.Delivery.Infrastructure/"]
COPY ["backend/src/Creavers.Delivery.Api/Creavers.Delivery.Api.csproj", "backend/src/Creavers.Delivery.Api/"]
RUN dotnet restore "backend/src/Creavers.Delivery.Api/Creavers.Delivery.Api.csproj"
COPY . .
RUN dotnet publish "backend/src/Creavers.Delivery.Api/Creavers.Delivery.Api.csproj" -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && adduser --disabled-password --home /app --gecos "" appuser \
    && chown -R appuser /app
USER appuser
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Creavers.Delivery.Api.dll"]
