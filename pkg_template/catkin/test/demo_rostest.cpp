TEST(TestDemo, Test)
{
    EXPECT_TRUE(true);
}

int main(int argc, char **argv)
{
    try
    {
        ::testing::InitGoogleTest(&argc, argv);
        ros::init(argc, argv, "demo_rostest");
        ros::NodeHandle nh;
        return(RUN_ALL_TESTS());
    }
    catch (const std::exception &e)
    {
        std::cerr << e.what() << std::endl;
    }
    return (EXIT_FAILURE);
}

