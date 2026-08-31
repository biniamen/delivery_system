using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Creavers.Delivery.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddDriverLiveLocations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "driver_locations",
                columns: table => new
                {
                    DriverId = table.Column<Guid>(type: "uuid", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    AccuracyMeters = table.Column<double>(type: "double precision", nullable: false),
                    HeadingDegrees = table.Column<double>(type: "double precision", nullable: true),
                    SpeedMetersPerSecond = table.Column<double>(type: "double precision", nullable: true),
                    CapturedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    ReceivedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_driver_locations", x => x.DriverId);
                    table.ForeignKey(
                        name: "FK_driver_locations_users_DriverId",
                        column: x => x.DriverId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_driver_locations_ReceivedAtUtc",
                table: "driver_locations",
                column: "ReceivedAtUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "driver_locations");
        }
    }
}
