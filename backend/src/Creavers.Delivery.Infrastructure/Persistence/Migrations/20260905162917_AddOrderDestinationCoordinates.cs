using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Creavers.Delivery.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderDestinationCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "DeliveryLatitude",
                table: "orders",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DeliveryLongitude",
                table: "orders",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryLatitude",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "DeliveryLongitude",
                table: "orders");
        }
    }
}
