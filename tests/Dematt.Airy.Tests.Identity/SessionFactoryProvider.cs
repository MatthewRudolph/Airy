﻿using System.Diagnostics;
using System.IO;
using Dematt.Airy.Identity.Nhibernate;
using Dematt.Airy.Tests.Identity.Entities;
using NHibernate;
using NHibernate.Cfg;
using NHibernate.Tool.hbm2ddl;

namespace Dematt.Airy.Tests.Identity
{
    /// <summary>
    /// NHibernate session factory provider we only ever want one of these :-)
    /// </summary>
    public class SessionFactoryProvider
    {
        private readonly Configuration _configuration;

        /// <summary>
        /// Default constructer, builds a session factory looking in the app.config, web.config or hibernate.cfg.xml for config details.
        /// </summary>
        public SessionFactoryProvider()
        {
            _configuration = new Configuration();
            _configuration.Configure();
            CreateNHibernateSessionFactory();
        }

        /// <summary>
        /// Builds a session factory using the supplied configuration file.
        /// </summary>      
        public SessionFactoryProvider(string nHhibernateConfigFile)
        {
            _configuration = new Configuration();
            _configuration.Configure(nHhibernateConfigFile);
            CreateNHibernateSessionFactory();
        }


        /// <summary>
        /// The NHibernate session factory use to obtain sessions.
        /// </summary>
        public ISessionFactory DefaultSessionFactory;

        /// <summary>
        /// Builds the database schema.
        /// </summary>        
        public void BuildSchema()
        {
            // Build the schema.
            var createSchemaSql = new StringWriter();
            var schemaExport = new SchemaExport(_configuration);

            // Drop the existing schema.
            schemaExport.Drop(true, true);

            // Print the Sql that will be used to build the schema.
            schemaExport.Create(createSchemaSql, false);
            Debug.Print(createSchemaSql.ToString());

            // Create the schema.
            schemaExport.Create(false, true);
        }

        /// <summary>
        /// Creates the NHibernare session factory.
        /// </summary>
        private void CreateNHibernateSessionFactory()
        {
            if (DefaultSessionFactory == null)
            {
                // Build and add the mappings for the test domain entities.
                var domainTypes = new[] { typeof(TestAddress), typeof(TestCar) };
                var domainMapper = new DefaultModelMapper();
                _configuration.AddMapping(domainMapper.CompileMappingFor(domainTypes));

                // Build and add the mappings for ASP.Net Identity entities.
                var mappingHelper = new MappingHelper<TestUser, string, TestLogin, TestRole, string, TestClaim, int>();
                // YOU CAN customise the ASP.Net Identity User mapping if required, before adding the mappings to the configuration.
                mappingHelper.Mapper.Class<TestUser>(u =>
                {
                    u.Bag(x => x.CarsAvailable, c =>
                    {
                        c.Inverse(true);
                    }, r => r.ManyToMany());
                });
                _configuration.AddMapping(mappingHelper.GetMappingsToMatchEfIdentity());
                DefaultSessionFactory = _configuration.BuildSessionFactory();
            }
        }
    }
}
